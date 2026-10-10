function __Battle_RegisterBoard(_board) {
    if (!variable_global_exists("boards_array")) global.boards_array = [];
    if (!variable_global_exists("board_uid")) global.board_uid = 0;
    _board.board_number = global.board_uid;
    global.board_uid++;
    array_push(global.boards_array, _board);
    return _board;
}

function __Battle_RemoveBoard(_board) {
    if (!variable_global_exists("boards_array")) return;
    // Do not capture `_board` inside an anonymous predicate here. In current
    // GameMaker runtimes the callback can outlive this argument scope and then
    // raise "not set before reading" while a board is being destroyed.
    for (var idx = array_length(global.boards_array) - 1; idx >= 0; idx--) {
        if (global.boards_array[idx] == _board) {
            array_delete(global.boards_array, idx, 1);
            return;
        }
    }
}

function __Battle_RemoveBoardController(_controller){
	if (!variable_global_exists("boards_controller_array")) return;
    for (var idx = array_length(global.boards_controller_array) - 1; idx >= 0; idx--) {
        if (global.boards_controller_array[idx] == _controller) {
            array_delete(global.boards_controller_array, idx, 1);
            return;
        }
    }
}
function __Battle_Iloop(_index, _list) {
    var _len = array_length(_list);
    if (_len <= 0) return 0;
    _index = _index mod _len;
    if (_index < 0) _index += _len;
    return _index;
}

/// Stable description of the data that changes the cached board mask/frame.
/// Bullets still redraw onto battle_board._surface every frame; only the
/// expensive board geometry (including composite edge sampling) is reused.
function Battle_BoardRenderSignature() {
    if(!variable_global_exists("boards_array")) return "no-boards";
    var result=string(battle_board.color_bg)+"|"+string(battle_board.alpha_bg)+"|"+string(battle_board.alpha_frame);
    var boards=global.boards_array;
    result+="|n="+string(array_length(boards));
    for(var board_index=0;board_index<array_length(boards);board_index++){
        var board=boards[board_index];
        if(!is_struct(board)){
            result+="|invalid";
            continue;
        }
        result+="|"+string(board.board_number)
            +","+string(board._destroyed)
            +","+string(board.x)+","+string(board.y)
            +","+string(board.angle)+","+string(board.cover)
            +","+string(board.board_depth)+","+string(board.color_frame);
        if(variable_struct_exists(board,"radius_x")){
            result+=",ellipse,"+string(board.radius_x)+","+string(board.radius_y)+","+string(board.precision);
        }
        if(variable_struct_exists(board,"listVertex")&&is_array(board.listVertex)){
            var vertices=board.listVertex;
            result+=",vertices="+string(array_length(vertices));
            // Every supported geometry mutation finishes through updateDivide,
            // which advances this revision. Avoid formatting dozens of point
            // coordinates into a new string on every morph frame.
            if(variable_struct_exists(board,"_geometry_revision")){
                var render_revision=board._geometry_revision;
                // Runtime runs at 120 Step/s while authored battle time is 60
                // logical frames/s. Collision still receives every intermediate
                // contour, but rebuilding the board surfaces twice for the same
                // logical frame is wasted work. The exact final pose refreshes
                // immediately when editor_morphing becomes false.
                if(variable_struct_exists(board,"editor_morphing")&&board.editor_morphing){
                    var morph_delta=variable_global_exists("delta_time_factor")?max(0.0001,global.delta_time_factor):1;
                    var render_stride=max(1,round(1/morph_delta));
                    render_revision=floor(render_revision/render_stride);
                }
                result+=",revision="+string(render_revision);
            }
            else{
                for(var vertex_index=0;vertex_index<array_length(vertices);vertex_index++){
                    var vertex=vertices[vertex_index];
                    if(is_array(vertex)&&array_length(vertex)>=2) result+=","+string(vertex[0])+","+string(vertex[1]);
                    else result+=",invalid";
                }
            }
        }
    }
    return result;
}

/// Exact authored-shape containment used by the composite border. Gameplay
/// collision uses this same boundary: the five-pixel border is visual only.
function __Battle_BoardShapeContainsExact(_board,_x,_y) {
    if(!is_struct(_board)||_board._destroyed) return false;
    if(struct_exists(_board,"listVertex")&&struct_exists(_board,"relativeContains")){
        return _board.relativeContains(_x-_board.x,_y-_board.y,_board.listVertex);
    }
    if(struct_exists(_board,"radius_x")&&struct_exists(_board,"radius_y")){
        var local=RotateAround(_board.x,_board.y,_x,_y,_board.x,_board.y,-_board.angle);
        var rx=max(0.0001,abs(_board.radius_x)),ry=max(0.0001,abs(_board.radius_y));
        return sqr((local[0]-_board.x)/rx)+sqr((local[1]-_board.y)/ry)<=1;
    }
    return _board.contains(_x,_y);
}

/// The final playable area is the union of every ADD board minus every
/// SUBTRACT board. Border visibility has to use this same composition or each
/// overlapping frame leaves its complete internal outline behind.
function __Battle_BoardCompositeContains(_x,_y) {
    if(!variable_global_exists("boards_array")) return false;
    var inside_add=false,inside_cut=false;
    for(var i=0;i<array_length(global.boards_array);i++){
        var board=global.boards_array[i];
        if(!is_struct(board)||board._destroyed||!__Battle_BoardShapeContainsExact(board,_x,_y)) continue;
        if(board.cover) inside_cut=true;
        else inside_add=true;
    }
    return inside_add&&!inside_cut;
}

function __Battle_DrawCompositeBorderRun(_ax,_ay,_bx,_by,_color,_alpha) {
    draw_set_alpha(_alpha);
    draw_line_width_color(_ax,_ay,_bx,_by,5,_color,_color);
    draw_circle_color(_ax,_ay,2.5,_color,_color,false);
    draw_circle_color(_bx,_by,2.5,_color,_color,false);
}

/// Draw only portions of an authored edge that remain on the boundary of the
/// composed playable area. Samples three pixels to either side distinguish an
/// external/cut boundary from a line buried inside another ADD frame.
function __Battle_DrawCompositeBorderSegment(_ax,_ay,_bx,_by,_color,_alpha) {
    var edge_length=point_distance(_ax,_ay,_bx,_by);
    if(edge_length<=0.0001) return;
    var nx=-(_by-_ay)/edge_length*3;
    var ny= (_bx-_ax)/edge_length*3;
    var piece_count=max(1,ceil(edge_length/2));
    var run_start=-1;
    for(var piece=0;piece<piece_count;piece++){
        var t0=piece/piece_count,t1=(piece+1)/piece_count,tm=(t0+t1)*0.5;
        var mx=lerp(_ax,_bx,tm),my=lerp(_ay,_by,tm);
        var side_a=__Battle_BoardCompositeContains(mx+nx,my+ny);
        var side_b=__Battle_BoardCompositeContains(mx-nx,my-ny);
        var edge_is_visible=side_a!=side_b;
        if(edge_is_visible&&run_start<0) run_start=t0;
        if(!edge_is_visible&&run_start>=0){
            __Battle_DrawCompositeBorderRun(lerp(_ax,_bx,run_start),lerp(_ay,_by,run_start),lerp(_ax,_bx,t0),lerp(_ay,_by,t0),_color,_alpha);
            run_start=-1;
        }
    }
    if(run_start>=0) __Battle_DrawCompositeBorderRun(lerp(_ax,_bx,run_start),lerp(_ay,_by,run_start),_bx,_by,_color,_alpha);
}

// 直接创建一个框，创建后需要手动添加顶点
// Create an Board directly, you need to add vertexes by yourself
function Battle_CreateBoardPoints(x, y, board_depth = 0, angle = 0, rotate = 0, cover = 0) {
    var board = {
        _destroyed: false,
        x: x,
        y: y,
        angle: angle,
        rotate: rotate,
        rect: 0,
        cover: cover,
        board_depth: board_depth,
        board_number: -1,
        color_frame: c_white,
        isCollide: array_create(4, 0),
        listVertex: [],
        listDivideIndex: [],
        listVertex_Outline: [],
        _triangulation_exact: false,
        _convex: false,
        _local_min_x: 0,
        _local_max_x: 0,
        _local_min_y: 0,
        _local_max_y: 0,
        _geometry_revision: 0,
        _contains_angle_cache: undefined,
        _contains_sin_cache: 0,
        _contains_cos_cache: 1,

        contains: function(_x, _y, _listVertex = listVertex) {
            return relativeContains(_x - x, _y - y, _listVertex);
        },

        relativeContains: function(_x, _y, _listVertex = listVertex) {
            var size = array_length(_listVertex);
            if (size < 2) return false;

            if(is_undefined(_contains_angle_cache)||_contains_angle_cache!=angle){
                _contains_angle_cache=angle;
                _contains_sin_cache=dsin(angle);
                _contains_cos_cache=dcos(angle);
            }
            var vsin = _contains_sin_cache,
                vcos = _contains_cos_cache;
            var xx = _x * vcos - _y * vsin,
                yy = _x * vsin + _y * vcos;

            // Composite-border sampling calls containment hundreds of times
            // while one handle is moving. Reject outside points before the
            // general ray test, and use a no-allocation half-plane test for
            // the overwhelmingly common convex editor frames.
            if(xx<_local_min_x||xx>_local_max_x||yy<_local_min_y||yy>_local_max_y) return false;
            if(_convex){
                var has_positive=false,has_negative=false;
                var convex_previous=_listVertex[size-1];
                for(var convex_index=0;convex_index<size;convex_index++){
                    var convex_current=_listVertex[convex_index];
                    var convex_cross=(convex_current[0]-convex_previous[0])*(yy-convex_previous[1])
                        -(convex_current[1]-convex_previous[1])*(xx-convex_previous[0]);
                    if(convex_cross>0.0001) has_positive=true;
                    else if(convex_cross<-0.0001) has_negative=true;
                    if(has_positive&&has_negative) return false;
                    convex_previous=convex_current;
                }
                return true;
            }

            var isAllHor = true,
                prevTrend = false,
                prevHasIntersection = false;
            var prev = _listVertex[size - 1],
                cur;

            for (var i = size - 2; i >= 0; i--) {
                cur = _listVertex[i];
                if (prev[1] != cur[1]) {
                    isAllHor = false;
                    prevTrend = cur[1] < prev[1];
                    prevHasIntersection = (yy >= min(prev[1], cur[1]) && yy <= max(prev[1], cur[1]));
                    break;
                }
                prev = cur;
            }
            if (isAllHor) return false;

            var intersections = [], count = 0;
            prev = _listVertex[size - 1];
            for (var i = 0; i < size; i++) {
                cur = _listVertex[i];
                if (prev[1] != cur[1]) {
                    var hasIntersection = false;
                    var trend = cur[1] > prev[1];
                    if (trend != prevTrend || !prevHasIntersection) {
                        if (yy >= min(prev[1], cur[1]) && yy <= max(prev[1], cur[1])) {
                            hasIntersection = true;
                            intersections[count] = prev[0] + (cur[0] - prev[0]) * (yy - prev[1]) / (cur[1] - prev[1]);
                            count++;
                        }
                    }
                    if (trend != prevTrend) prevTrend = trend;
                    prevHasIntersection = hasIntersection;
                }
                prev = cur;
            }
            if (count == 0) return false;

            array_sort(intersections, true);
            var isInside = false;
            for (var i = 0; i < count; i++) {
                if (intersections[i] > xx) return isInside;
                isInside = !isInside;
            }
            return false;
        },

        limit: function(_x, _y, _listVertex = listVertex) {
            var size = array_length(_listVertex);
            if (size == 0) return [_x, _y];
            if (size == 1) {
                var vertex = _listVertex[0];
                return [vertex[0] + x, vertex[1] + y];
            }

            _x -= x;
            _y -= y;
            var vsin = dsin(-angle),
                vcos = dcos(-angle);
            var xx = _x * vcos + _y * vsin,
                yy = -_x * vsin + _y * vcos;

            var nearestPos, nearestDis = -1;
            var prev = _listVertex[size - 1],
                cur;
            for (var i = 0; i < size; i++) {
                cur = _listVertex[i];
                var edge_length_squared=sqr(cur[1]-prev[1])+sqr(cur[0]-prev[0]);
                if(edge_length_squared<=0.000001){prev=cur;continue;}
                if ((prev[0] - xx) * (prev[0] - cur[0]) + (prev[1] - yy) * (prev[1] - cur[1]) < 0) {
                    var dis = point_distance(xx, yy, prev[0], prev[1]);
                    if (dis < nearestDis || nearestDis == -1) {
                        nearestDis = dis;
                        nearestPos = prev;
                    }
                } else if ((cur[0] - xx) * (cur[0] - prev[0]) + (cur[1] - yy) * (cur[1] - prev[1]) < 0) {
                    var dis = point_distance(xx, yy, cur[0], cur[1]);
                    if (dis < nearestDis || nearestDis == -1) {
                        nearestDis = dis;
                        nearestPos = cur;
                    }
                } else {
                    var k = ((yy - prev[1]) * (cur[0] - prev[0]) - (xx - prev[0]) * (cur[1] - prev[1])) / edge_length_squared;
                    var dis = abs(k) * point_distance(prev[0], prev[1], cur[0], cur[1]);
                    if (dis < nearestDis || nearestDis == -1) {
                        nearestDis = dis;
                        nearestPos = [xx + k * (cur[1] - prev[1]), yy + k * (prev[0] - cur[0])];
                    }
                }
                prev = cur;
            }
            // Coincident/degenerate vertices can exist for a frame while the
            // author is dragging.  Always return a coordinate pair.
            if(!is_array(nearestPos)) nearestPos=[xx,yy];
            var resultx = nearestPos[0] * vcos - nearestPos[1] * vsin;
            var resulty = nearestPos[0] * vsin + nearestPos[1] * vcos;
            return [resultx + x, resulty + y];
        },

        updateDivide: function() {
            _geometry_revision+=1;
            var previous_divide=listDivideIndex;
            var next_divide=[];
            var size = array_length(listVertex);
            if (size < 3) {listDivideIndex=[];_triangulation_exact=false;_convex=false;return;}

            _local_min_x=listVertex[0][0];_local_max_x=_local_min_x;
            _local_min_y=listVertex[0][1];_local_max_y=_local_min_y;
            var convex_positive=false,convex_negative=false;
            for(var geometry_index=0;geometry_index<size;geometry_index++){
                var geometry_point=listVertex[geometry_index];
                _local_min_x=min(_local_min_x,geometry_point[0]);_local_max_x=max(_local_max_x,geometry_point[0]);
                _local_min_y=min(_local_min_y,geometry_point[1]);_local_max_y=max(_local_max_y,geometry_point[1]);
                var convex_a=listVertex[__Battle_Iloop(geometry_index-1,listVertex)];
                var convex_b=geometry_point;
                var convex_c=listVertex[__Battle_Iloop(geometry_index+1,listVertex)];
                var turn_cross=(convex_b[0]-convex_a[0])*(convex_c[1]-convex_b[1])
                    -(convex_b[1]-convex_a[1])*(convex_c[0]-convex_b[0]);
                if(turn_cross>0.0001) convex_positive=true;
                else if(turn_cross<-0.0001) convex_negative=true;
            }
            _convex=!(convex_positive&&convex_negative);

            for (var i = 0; i < size; i++) {
                var a = listVertex[i];
                var b = listVertex[__Battle_Iloop(i + 1, listVertex)];
                var c = listVertex[__Battle_Iloop(i - 1, listVertex)];

                var ax = a[0], ay = a[1];
                var bx = b[0], by = b[1];
                var cx = c[0], cy = c[1];
                var dangle = (point_direction(ax, ay, bx, by) - point_direction(ax, ay, cx, cy)) / 2;

                var tangent=dtan(dangle);
                var miter=abs(tangent)<0.001?0:clamp(5/tangent,-20,20);
                listVertex_Outline[i] = [
                    (ax + bx) / 2 + lengthdir_x(5, point_direction(ax, ay, bx, by) + 90) + lengthdir_x(point_distance(ax, ay, bx, by) / 2 + miter, point_direction(bx, by, ax, ay)),
                    (ay + by) / 2 + lengthdir_y(5, point_direction(ax, ay, bx, by) + 90) + lengthdir_y(point_distance(ax, ay, bx, by) / 2 + miter, point_direction(bx, by, ax, ay))
                ];
            }

            // Convex contours (including every frame of the built-in smooth
            // shape morph) have an exact fan triangulation. Running the general
            // O(n^3) ear clipper for 64 near-circular points caused a visible
            // freeze on every transition.
            if(_convex){
                listDivideIndex=[];
                for(var convex_fan_index=1;convex_fan_index<size-1;convex_fan_index++) array_push(listDivideIndex,[0,convex_fan_index,convex_fan_index+1]);
                _triangulation_exact=true;
                return;
            }

            // Stable ear clipping for arbitrary simple concave polygons.  The
            // old midpoint test occasionally failed while a point was being
            // dragged, clearing every fill triangle for that frame.
            var signed_area=0;
            for(var area_index=0;area_index<size;area_index++){
                var area_a=listVertex[area_index];
                var area_b=listVertex[__Battle_Iloop(area_index+1,listVertex)];
                signed_area+=area_a[0]*area_b[1]-area_b[0]*area_a[1];
            }
            var winding=sign(signed_area);
            if(winding==0){if(array_length(previous_divide)>0) listDivideIndex=previous_divide;_triangulation_exact=false;return;}
            var marker=[];
            for(var marker_index=0;marker_index<size;marker_index++) array_push(marker,marker_index);
            var editor_point_inside_triangle=function(_p,_a,_b,_c,_winding){
                var c1=(_b[0]-_a[0])*(_p[1]-_a[1])-(_b[1]-_a[1])*(_p[0]-_a[0]);
                var c2=(_c[0]-_b[0])*(_p[1]-_b[1])-(_c[1]-_b[1])*(_p[0]-_b[0]);
                var c3=(_a[0]-_c[0])*(_p[1]-_c[1])-(_a[1]-_c[1])*(_p[0]-_c[0]);
                return _winding>0?(c1>=-0.001&&c2>=-0.001&&c3>=-0.001):(c1<=0.001&&c2<=0.001&&c3<=0.001);
            };
            var guard=0;
            while(array_length(marker)>3&&guard<size*size){
                guard+=1;
                var clipped=false;
                for(var ear_index=0;ear_index<array_length(marker);ear_index++){
                    var prev_index=marker[__Battle_Iloop(ear_index-1,marker)];
                    var curr_index=marker[ear_index];
                    var next_index=marker[__Battle_Iloop(ear_index+1,marker)];
                    var pa=listVertex[prev_index],pb=listVertex[curr_index],pc=listVertex[next_index];
                    var cross=(pb[0]-pa[0])*(pc[1]-pb[1])-(pb[1]-pa[1])*(pc[0]-pb[0]);
                    if(cross*winding<=0.001) continue;
                    var contains_point=false;
                    for(var test_index=0;test_index<array_length(marker);test_index++){
                        var candidate=marker[test_index];
                        if(candidate==prev_index||candidate==curr_index||candidate==next_index) continue;
                        if(editor_point_inside_triangle(listVertex[candidate],pa,pb,pc,winding)){contains_point=true;break;}
                    }
                    if(contains_point) continue;
                    array_push(next_divide,[prev_index,curr_index,next_index]);
                    array_delete(marker,ear_index,1);
                    clipped=true;
                    break;
                }
                if(!clipped) break;
            }
            if(array_length(marker)==3) array_push(next_divide,[marker[0],marker[1],marker[2]]);
            if(array_length(next_divide)==size-2){listDivideIndex=next_divide;_triangulation_exact=true;}
            else if(array_length(previous_divide)>0){listDivideIndex=previous_divide;_triangulation_exact=false;}
            else{
                // Last-resort fan keeps the board visible for malformed/self-
                // intersecting edits.  The editor can then highlight/fix the
                // vertices instead of making the entire board disappear.
                listDivideIndex=[];
                for(var fan_index=1;fan_index<size-1;fan_index++) array_push(listDivideIndex,[0,fan_index,fan_index+1]);
                _triangulation_exact=false;
            }
        },

        // Draw the polygon into the alpha channel using an even/odd scanline
        // fill.  This deliberately does not depend on the triangulation above:
        // editor-created concave and self-intersecting frames must keep a
        // stable interior while a vertex is being dragged.
        drawFillAlpha: function(_alpha) {
            var vertex_count=array_length(listVertex);
            if(vertex_count<3) return;

            var vsin=dsin(-angle),vcos=dcos(-angle);
            // Ordinary rectangles, triangles and simple concave polygons all
            // have an exact ear-clipped triangulation. Submit those triangles
            // in one GPU primitive instead of scanning up to 480 rows in GML.
            if(_triangulation_exact&&array_length(listDivideIndex)==vertex_count-2){
                draw_set_alpha(_alpha);
                draw_primitive_begin(pr_trianglelist);
                for(var triangle_index=0;triangle_index<array_length(listDivideIndex);triangle_index++){
                    var triangle=listDivideIndex[triangle_index];
                    for(var corner_index=0;corner_index<3;corner_index++){
                        var point=listVertex[triangle[corner_index]];
                        draw_vertex(x+point[0]*vcos-point[1]*vsin,y+point[0]*vsin+point[1]*vcos);
                    }
                }
                draw_primitive_end();
                return;
            }

            // Self-intersecting or temporarily degenerate authored polygons
            // retain the stable even/odd fallback while their vertex is held.
            var world_vertices=[];
            var min_y=1000000,max_y=-1000000;
            for(var vertex_index=0;vertex_index<vertex_count;vertex_index++){
                var source=listVertex[vertex_index];
                var world_x=x+source[0]*vcos-source[1]*vsin;
                var world_y=y+source[0]*vsin+source[1]*vcos;
                array_push(world_vertices,[world_x,world_y]);
                min_y=min(min_y,world_y);
                max_y=max(max_y,world_y);
            }

            draw_set_alpha(_alpha);
            var scan_start=max(0,floor(min_y));
            var scan_end=min(479,ceil(max_y));
            for(var scan_y=scan_start;scan_y<=scan_end;scan_y++){
                var sample_y=scan_y+0.5;
                var intersections=[];
                for(var edge_index=0;edge_index<vertex_count;edge_index++){
                    var edge_a=world_vertices[edge_index];
                    var edge_b=world_vertices[__Battle_Iloop(edge_index+1,world_vertices)];
                    var crosses=(edge_a[1]<=sample_y&&edge_b[1]>sample_y)||(edge_b[1]<=sample_y&&edge_a[1]>sample_y);
                    if(crosses){
                        var amount=(sample_y-edge_a[1])/(edge_b[1]-edge_a[1]);
                        array_push(intersections,edge_a[0]+(edge_b[0]-edge_a[0])*amount);
                    }
                }

                // The lists are tiny (normally 3-32 entries), so insertion
                // sorting avoids relying on callback capture rules here.
                for(var sort_index=1;sort_index<array_length(intersections);sort_index++){
                    var sort_value=intersections[sort_index];
                    var insert_index=sort_index-1;
                    while(insert_index>=0&&intersections[insert_index]>sort_value){
                        intersections[insert_index+1]=intersections[insert_index];
                        insert_index-=1;
                    }
                    intersections[insert_index+1]=sort_value;
                }
                for(var pair_index=0;pair_index+1<array_length(intersections);pair_index+=2){
                    draw_rectangle(intersections[pair_index],scan_y,intersections[pair_index+1],scan_y+1,false);
                }
            }
        },

        replaceSurfaceAlpha: function() {
            gpu_set_colorwriteenable(false, false, false, true);
            gpu_set_blendenable(false);
            surface_set_target(battle_board._surface_mask);

            drawFillAlpha(!cover);
            surface_reset_target();

            if (!cover) {
                surface_set_target(battle_board._surface_board_extra);
                drawFillAlpha(0);
                surface_reset_target();
            }
            gpu_set_blendenable(true);
            gpu_set_colorwriteenable(true, true, true, true);
        },

        drawBorder: function() {
            surface_set_target(battle_board._surface_board_cover);
            var vsin = dsin(-angle), vcos = dcos(-angle);
            // Every edge uses the same five-pixel screen-space stroke.  Joins
            // are filled with a radius-2.5 disc, so dragging a vertex cannot
            // thin an edge, expose a seam, or turn a sharp corner into a wedge.
            var vertex_count=array_length(listVertex);
            var active_board_count=0,only_active_board=undefined;
            for(var active_index=0;active_index<array_length(global.boards_array);active_index++){
                var active_board=global.boards_array[active_index];
                if(is_struct(active_board)&&!active_board._destroyed){active_board_count+=1;only_active_board=active_board;if(active_board_count>1) break;}
            }
            var direct_border=active_board_count==1&&only_active_board==self&&!cover;
            draw_set_alpha(battle_board.alpha_frame);
            for(var i=0;i<vertex_count;i++){
                var a=listVertex[i];
                var b=listVertex[__Battle_Iloop(i+1,listVertex)];
                var ax=a[0]*vcos-a[1]*vsin;
                var ay=a[0]*vsin+a[1]*vcos;
                var bx=b[0]*vcos-b[1]*vsin;
                var by=b[0]*vsin+b[1]*vcos;
                if(direct_border) __Battle_DrawCompositeBorderRun(x+ax,y+ay,x+bx,y+by,color_frame,battle_board.alpha_frame);
                else __Battle_DrawCompositeBorderSegment(x+ax,y+ay,x+bx,y+by,color_frame,battle_board.alpha_frame);
            }
            draw_set_alpha(1);
            surface_reset_target();
        },

        update: function() {
            angle += rotate;
        },

        destroy: function() {
            if (_destroyed) return;
            _destroyed = true;
            __Battle_RemoveBoard(self);
        }
    };

    return __Battle_RegisterBoard(board);
}

//创建一个矩形的框
//Create a Board that is rect
function Battle_CreateBoardRect(x, y, up, down, left, right, board_depth = 0, angle = 0, rotate = 0, cover = 0) {
    var rect = Battle_CreateBoardPoints(x, y, board_depth, angle, rotate, cover);
    rect.up = up;
    rect.down = down;
    rect.left = left;
    rect.right = right;
    rect.rect = 1;
    rect._geometry_cache_valid = false;
    rect._geometry_cache_up = 0;
    rect._geometry_cache_down = 0;
    rect._geometry_cache_left = 0;
    rect._geometry_cache_right = 0;
    rect.update = method(rect, function() {
        self.angle += self.rotate;
        if(self._geometry_cache_valid
        &&self._geometry_cache_up==self.up&&self._geometry_cache_down==self.down
        &&self._geometry_cache_left==self.left&&self._geometry_cache_right==self.right) return;
        self.listVertex = [
            [-self.left, -self.up],
            [self.right, -self.up],
            [self.right, self.down],
            [-self.left, self.down]
        ];
        self.updateDivide();
        self._geometry_cache_up=self.up;
        self._geometry_cache_down=self.down;
        self._geometry_cache_left=self.left;
        self._geometry_cache_right=self.right;
        self._geometry_cache_valid=true;
    });
    rect.update();
    return rect;
}

//创建一个圆形的框
//Create a Board that is circle
function Battle_CreateBoardCircle(x, y, radius, board_depth = 0, cover = 0) {
    return Battle_CreateBoardEllipse(x, y, radius, radius, board_depth, 0, 0, cover);
}

//创建一个椭圆的框
//Create a Board that is ellipse
function Battle_CreateBoardEllipse(x, y, radius_x, radius_y, board_depth = 0, angle = 0, rotate = 0, cover = 0) {
    var ellipse = {
        _destroyed: false,
        x: x,
        y: y,
        radius_x: radius_x,
        radius_y: radius_y,
        precision: 360,
        angle: angle,
        rotate: rotate,
        cover: cover,
        board_depth: board_depth,
        board_number: -1,
        color_frame: c_white,
        isCollide: array_create(4, 0),

        contains: function(_x, _y) {
            var pos = RotateAround(x, y, _x, _y, x, y, -angle);
            return sqr(pos[0] - x) * sqr(radius_y) + sqr(pos[1] - y) * sqr(radius_x) <= sqr(radius_x * radius_y);
        },

        limit: function(_x, _y) {
            var pos = RotateAround(x, y, _x, _y, x, y, -angle);
            pos[0] -= x;
            pos[1] -= y;
            _x -= x;
            _y -= y;
            var k = (pos[0] == 0) ? 99999 : pos[1] / pos[0];
            var len = radius_x * radius_y * sqrt((1 + k * k) / (radius_y * radius_y + sqr(radius_x * k)));
            var mul = len / sqrt(sqr(_x) + sqr(_y));
            return [_x * mul + x, _y * mul + y];
        },

        replaceSurfaceAlpha: function() {
            gpu_set_colorwriteenable(false, false, false, true);
            gpu_set_blendenable(false);
            surface_set_target(battle_board._surface_mask);
            draw_set_alpha(!cover);
            draw_primitive_begin(pr_trianglefan);
            draw_vertex(x, y);
            for (var i = 0; i <= precision; i++) {
                var pos = RotateAround(x, y, x + lengthdir_x(radius_x, i * 360 / precision), y + lengthdir_y(radius_y, i * 360 / precision), x, y, angle);
                draw_vertex(pos[0], pos[1]);
            }
            draw_primitive_end();
            surface_reset_target();
            gpu_set_blendenable(true);
            gpu_set_colorwriteenable(true, true, true, true);
        },

        drawBorder: function() {
            surface_set_target(battle_board._surface_board_cover);
            draw_set_alpha(battle_board.alpha_frame);
            // A rotated ellipse is approximated only for its outline.  Its
            // collision/fill remains the exact ellipse implementation above.
            var border_precision=max(48,min(180,ceil(max(radius_x,radius_y)*1.5)));
            var previous=RotateAround(x,y,x+radius_x,y,x,y,angle);
            for(var i=1;i<=border_precision;i++){
                var theta=i*360/border_precision;
                var local_x=x+dcos(theta)*radius_x;
                var local_y=y+dsin(theta)*radius_y;
                var current=RotateAround(x,y,local_x,local_y,x,y,angle);
                __Battle_DrawCompositeBorderSegment(previous[0],previous[1],current[0],current[1],color_frame,battle_board.alpha_frame);
                previous=current;
            }
            draw_set_alpha(1);
            surface_reset_target();
        },

        update: function() {
            angle += rotate;
        },

        destroy: function() {
            if (_destroyed) return;
            _destroyed = true;
            __Battle_RemoveBoard(self);
        }
    };

    return __Battle_RegisterBoard(ellipse);
}

//创建一个圆角矩形的框
//Create a Board that is roundrect
function Battle_CreateBoardRoundrect(x, y, size, precision, board_depth = 0, angle = 0, rotate = 0, cover = 0) {
    if (!variable_global_exists("boards_controller_array")) global.boards_controller_array = [];
    var roundrect = {
        _destroyed: false,
        x: x,
        y: y,
        size: size,
        precision: precision,
        board_depth: board_depth,
        angle: angle,
        rotate: rotate,
        cover: cover,
        hrect: Battle_CreateBoardRect(x, y, size / 2, size / 2, (size - precision * 2) / 2, (size - precision * 2) / 2, board_depth, angle, 0, cover),
        vrect: Battle_CreateBoardRect(x, y, (size - precision * 2) / 2, (size - precision * 2) / 2, size / 2, size / 2, board_depth, angle, 0, cover),
        circle_0: Battle_CreateBoardCircle(x + (size - precision * 2) / 2 - 1, y - (size - precision * 2) / 2 - 1, precision, board_depth, cover),
        circle_1: Battle_CreateBoardCircle(x - (size - precision * 2) / 2 - 1, y - (size - precision * 2) / 2 - 1, precision, board_depth, cover),
        circle_2: Battle_CreateBoardCircle(x - (size - precision * 2) / 2 - 1, y + (size - precision * 2) / 2 - 1, precision, board_depth, cover),
        circle_3: Battle_CreateBoardCircle(x + (size - precision * 2) / 2 - 1, y + (size - precision * 2) / 2 - 1, precision, board_depth, cover),

        update: function() {
            angle += rotate;

            hrect.angle = angle;
            hrect.up = size / 2;
            hrect.down = size / 2;
            hrect.left = (size - precision * 2) / 2;
            hrect.right = (size - precision * 2) / 2;
            hrect.x = x;
            hrect.y = y;
            hrect.cover = cover;
            hrect.board_depth = board_depth;

            vrect.angle = angle;
            vrect.up = (size - precision * 2) / 2;
            vrect.down = (size - precision * 2) / 2;
            vrect.left = size / 2;
            vrect.right = size / 2;
            vrect.x = x;
            vrect.y = y;
            vrect.cover = cover;
            vrect.board_depth = board_depth;

            circle_0.radius_x = precision;
            circle_0.radius_y = precision;
            circle_0.x = x + lengthdir_x(((size - precision * 2) / 2) * 1.414, angle + 45) - 1;
            circle_0.y = y + lengthdir_y(((size - precision * 2) / 2) * 1.414, angle + 45) - 1;
            circle_0.cover = cover;
            circle_0.board_depth = board_depth;

            circle_1.radius_x = precision;
            circle_1.radius_y = precision;
            circle_1.x = x + lengthdir_x(((size - precision * 2) / 2) * 1.414, angle + 45 + 90 * 1) - 1;
            circle_1.y = y + lengthdir_y(((size - precision * 2) / 2) * 1.414, angle + 45 + 90 * 1) - 1;
            circle_1.cover = cover;
            circle_1.board_depth = board_depth;

            circle_2.radius_x = precision;
            circle_2.radius_y = precision;
            circle_2.x = x + lengthdir_x(((size - precision * 2) / 2) * 1.414, angle + 45 + 90 * 2) - 1;
            circle_2.y = y + lengthdir_y(((size - precision * 2) / 2) * 1.414, angle + 45 + 90 * 2) - 1;
            circle_2.cover = cover;
            circle_2.board_depth = board_depth;

            circle_3.radius_x = precision;
            circle_3.radius_y = precision;
            circle_3.x = x + lengthdir_x(((size - precision * 2) / 2) * 1.414, angle + 45 + 90 * 3) - 1;
            circle_3.y = y + lengthdir_y(((size - precision * 2) / 2) * 1.414, angle + 45 + 90 * 3) - 1;
            circle_3.cover = cover;
            circle_3.board_depth = board_depth;
        },

        destroy: function() {
            if (_destroyed) return;
			__Battle_RemoveBoardController(self);
            _destroyed = true;
            hrect.destroy();
            vrect.destroy();
            circle_0.destroy();
            circle_1.destroy();
            circle_2.destroy();
            circle_3.destroy();
        }
    };

    array_push(global.boards_controller_array, roundrect);
    return roundrect;
}
//给指定框添加顶点,最少要三个顶点才能正常运行
//注意：顶点坐标顺序一定要按顺时针排列否则会出显示问题
//Add vertex to the Board,you need to add at least 3 vertexes to make it work properly
//WARNING:The arrangement of vertexes' positions must be clockwise or visual problem happens
function Battle_AddBoardVertex(board, vertex_x, vertex_y) {
    var BOARD = board;
    var X = vertex_x;
    var Y = vertex_y;
    var VERTEXLIST = BOARD.listVertex;

    array_push(VERTEXLIST, [X, Y]);
    BOARD.updateDivide();
}

// -------------------------------------------------------------------------
// 减框公开 API：不再记普通框函数最后一个神秘的 cover=1。

/// @function Battle_CutBoardCreateRect(x,y,up,down,left,right,board_depth,angle,rotate)
/// @param {Real} x 中心 X
/// @param {Real} y 中心 Y
/// @param {Real} up 向上半径
/// @param {Real} down 向下半径
/// @param {Real} left 向左半径
/// @param {Real} right 向右半径
/// @param {Real} [board_depth=0] 框层级
/// @param {Real} [angle=0] 初始角度
/// @param {Real} [rotate=0] 每步自转角度
function Battle_CutBoardCreateRect(x,y,up,down,left,right,board_depth=0,angle=0,rotate=0){
    return Battle_CreateBoardRect(x,y,up,down,left,right,board_depth,angle,rotate,1);
}

/// @function Battle_CutBoardCreateCircle(x,y,radius,board_depth)
/// @param {Real} x 中心 X
/// @param {Real} y 中心 Y
/// @param {Real} radius 半径
/// @param {Real} [board_depth=0] 框层级
function Battle_CutBoardCreateCircle(x,y,radius,board_depth=0){
    return Battle_CreateBoardCircle(x,y,radius,board_depth,1);
}

/// @function Battle_CutBoardCreateEllipse(x,y,radius_x,radius_y,board_depth,angle,rotate)
/// @param {Real} x 中心 X
/// @param {Real} y 中心 Y
/// @param {Real} radius_x 横半径
/// @param {Real} radius_y 纵半径
/// @param {Real} [board_depth=0] 框层级
/// @param {Real} [angle=0] 初始角度
/// @param {Real} [rotate=0] 每步自转角度
function Battle_CutBoardCreateEllipse(x,y,radius_x,radius_y,board_depth=0,angle=0,rotate=0){
    return Battle_CreateBoardEllipse(x,y,radius_x,radius_y,board_depth,angle,rotate,1);
}

/// @function Battle_CutBoardCreateRoundrect(x,y,size,corner_radius,board_depth,angle,rotate)
/// @param {Real} x 中心 X
/// @param {Real} y 中心 Y
/// @param {Real} size 总尺寸
/// @param {Real} corner_radius 圆角半径
/// @param {Real} [board_depth=0] 框层级
/// @param {Real} [angle=0] 初始角度
/// @param {Real} [rotate=0] 每步自转角度
function Battle_CutBoardCreateRoundrect(x,y,size,corner_radius,board_depth=0,angle=0,rotate=0){
    return Battle_CreateBoardRoundrect(x,y,size,corner_radius,board_depth,angle,rotate,1);
}

/// @function Battle_CutBoardCreatePolygon(x,y,vertices,board_depth,angle,rotate)
/// @param {Real} x 中心 X
/// @param {Real} y 中心 Y
/// @param {Array<Array<Real>>} vertices 顺时针局部顶点，例如 [[-20,-20],[20,-20],[0,25]]
/// @param {Real} [board_depth=0] 框层级
/// @param {Real} [angle=0] 初始角度
/// @param {Real} [rotate=0] 每步自转角度
function Battle_CutBoardCreatePolygon(x,y,vertices,board_depth=0,angle=0,rotate=0){
    var board=Battle_CreateBoardPoints(x,y,board_depth,angle,rotate,1);
    for(var i=0;i<array_length(vertices);i++) Battle_AddBoardVertex(board,vertices[i][0],vertices[i][1]);
    return board;
}

/// @function Battle_CutBoardSetCircle(board,x,y,radius)
/// @param {Struct} board 圆形减框
/// @param {Real} x 中心 X
/// @param {Real} y 中心 Y
/// @param {Real} radius 半径
function Battle_CutBoardSetCircle(board,x,y,radius){
    if(!is_struct(board)||board._destroyed) return false;
    board.x=x;
    board.y=y;
    board.radius_x=radius;
    board.radius_y=radius;
    return true;
}

/// @function Battle_CutBoardSetEllipse(board,x,y,radius_x,radius_y,angle)
/// @param {Struct} board 椭圆减框
/// @param {Real} x 中心 X
/// @param {Real} y 中心 Y
/// @param {Real} radius_x 横半径
/// @param {Real} radius_y 纵半径
/// @param {Real} [angle=0] 角度
function Battle_CutBoardSetEllipse(board,x,y,radius_x,radius_y,angle=0){
    if(!is_struct(board)||board._destroyed) return false;
    board.x=x;
    board.y=y;
    board.radius_x=radius_x;
    board.radius_y=radius_y;
    board.angle=angle;
    return true;
}

/// @function Battle_CutBoardDestroy(board)
/// @param {Struct} board 要删除的减框
function Battle_CutBoardDestroy(board){
    if(!is_struct(board)||board._destroyed) return false;
    board.destroy();
    return true;
}

