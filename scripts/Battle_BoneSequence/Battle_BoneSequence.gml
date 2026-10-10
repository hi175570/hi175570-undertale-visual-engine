enum BONE_PATH_KIND {
    WAIT,
    MOVE,
    SINE,
    BEZIER,
    CUSTOM
}

/// @function Bone_EaseLinear(t)
/// @param {Real} t 0 到 1 的进度
/// @returns {Real}
function Bone_EaseLinear(t){
    return clamp(t,0,1);
}

/// @function Bone_EaseSineInOut(t)
/// @param {Real} t 0 到 1 的进度
/// @returns {Real}
function Bone_EaseSineInOut(t){
    t=clamp(t,0,1);
    return -(dcos(180*t)-1)*0.5;
}

/// @function Bone_PathWait(duration)
/// @param {Real} duration 停留帧数
/// @returns {Struct.BonePathSegment}
function Bone_PathWait(duration){
    return {kind:BONE_PATH_KIND.WAIT,duration:max(1,duration),spin:0,length_to:undefined,ease:Bone_EaseLinear};
}

/// @function Bone_PathMove(duration,target_x,target_y,spin,length_to,ease)
/// @param {Real} duration 移动帧数
/// @param {Real} target_x 终点 X
/// @param {Real} target_y 终点 Y
/// @param {Real} [spin=0] 本段总旋转角度
/// @param {Real} [length_to=undefined] 结束长度；不填则保持
/// @param {Function} [ease=Bone_EaseSineInOut] 进度曲线
/// @returns {Struct.BonePathSegment}
function Bone_PathMove(duration,target_x,target_y,spin=0,length_to=undefined,ease=Bone_EaseSineInOut){
    return {kind:BONE_PATH_KIND.MOVE,duration:max(1,duration),target_x:target_x,target_y:target_y,spin:spin,length_to:length_to,ease:ease};
}

/// @function Bone_PathSine(duration,start_x,start_y,end_x,end_y,amplitude,cycles,spin,length_to,ease,phase)
/// @param {Real} duration 移动帧数
/// @param {Real} start_x 起点 X
/// @param {Real} start_y 起点 Y
/// @param {Real} end_x 终点 X
/// @param {Real} end_y 终点 Y
/// @param {Real} amplitude 波浪振幅
/// @param {Real} cycles 波浪圈数
/// @param {Real} [spin=0] 本段总旋转角度
/// @param {Real} [length_to=undefined] 结束长度；不填则保持
/// @param {Function} [ease=Bone_EaseLinear] 进度曲线
/// @param {Real} [phase=0] 正弦初相位
/// @returns {Struct.BonePathSegment}
function Bone_PathSine(duration,start_x,start_y,end_x,end_y,amplitude,cycles,spin=0,length_to=undefined,ease=Bone_EaseLinear,phase=0){
    return {kind:BONE_PATH_KIND.SINE,duration:max(1,duration),start_x:start_x,start_y:start_y,end_x:end_x,end_y:end_y,amplitude:amplitude,cycles:cycles,phase:phase,spin:spin,length_to:length_to,ease:ease};
}

/// @function Bone_PathBezier(duration,points,spin,length_to,ease)
/// @param {Real} duration 移动帧数
/// @param {Array<Array<Real>>} points 控制点，例如 [[200,320],[320,240],[440,320]]
/// @param {Real} [spin=0] 本段总旋转角度
/// @param {Real} [length_to=undefined] 结束长度；不填则保持
/// @param {Function} [ease=Bone_EaseSineInOut] 进度曲线
/// @returns {Struct.BonePathSegment}
function Bone_PathBezier(duration,points,spin=0,length_to=undefined,ease=Bone_EaseSineInOut){
    return {kind:BONE_PATH_KIND.BEZIER,duration:max(1,duration),points:points,spin:spin,length_to:length_to,ease:ease};
}

/// @function Bone_PathCustom(duration,position_function,spin,length_to,ease,step_function)
/// @param {Real} duration 移动帧数
/// @param {Function} position_function 参数为 (t,start_x,start_y,bone,sequence,segment)，返回 [x,y]
/// @param {Real} [spin=0] 本段总旋转角度
/// @param {Real} [length_to=undefined] 结束长度；不填则保持
/// @param {Function} [ease=Bone_EaseLinear] 进度曲线
/// @param {Function} [step_function=undefined] 可选逐帧回调，参数同 position_function
/// @returns {Struct.BonePathSegment}
function Bone_PathCustom(duration,position_function,spin=0,length_to=undefined,ease=Bone_EaseLinear,step_function=undefined){
    return {kind:BONE_PATH_KIND.CUSTOM,duration:max(1,duration),position_function:position_function,step_function:step_function,spin:spin,length_to:length_to,ease:ease};
}

/// @function Bone_PathCreate(bone,segments,loop,destroy_on_finish)
/// @param {Instance} bone Battle_MakeBone 返回的实例
/// @param {Array<Struct.BonePathSegment>} segments 按顺序执行的动作列表
/// @param {Bool} [loop=false] 是否循环
/// @param {Bool} [destroy_on_finish=false] 结束后是否删除骨头
/// @returns {Struct.BonePathSequence}
function Bone_PathCreate(bone,segments,loop=false,destroy_on_finish=false){
    return {bone:bone,segments:segments,loop:loop,destroy_on_finish:destroy_on_finish,segment_index:0,segment_time:0,segment_started:false,finished:false,start_x:0,start_y:0,start_angle:0,start_length:0};
}

/// @function Bone_PathUpdate(sequence,delta)
/// @param {Struct.BonePathSequence} sequence Bone_PathCreate 返回的控制器
/// @param {Real} [delta=global.delta_time_factor] 本帧推进量
/// @returns {Bool} 仍在播放时返回 true
function Bone_PathUpdate(sequence,delta=global.delta_time_factor){
    if(!is_struct(sequence)||sequence.finished||!instance_exists(sequence.bone)) return false;
    var segment_count=array_length(sequence.segments);
    if(segment_count<=0){
        sequence.finished=true;
        return false;
    }

    var remaining=max(0,delta);
    var keep_advancing=true;
    while(keep_advancing&&!sequence.finished){
        var segment=sequence.segments[sequence.segment_index];
        if(!sequence.segment_started){
            sequence.segment_started=true;
            sequence.start_x=sequence.bone.x;
            sequence.start_y=sequence.bone.y;
            sequence.start_angle=sequence.bone.angle;
            sequence.start_length=sequence.bone.length;
        }

        sequence.segment_time+=remaining;
        var raw_progress=clamp(sequence.segment_time/segment.duration,0,1);
        var progress=segment.ease(raw_progress);
        var point=[sequence.start_x,sequence.start_y];

        switch(segment.kind){
            case BONE_PATH_KIND.MOVE:
                point=Trajectory_Linear(sequence.start_x,sequence.start_y,segment.target_x,segment.target_y,progress);
                break;
            case BONE_PATH_KIND.SINE:
                point=Trajectory_Sine(segment.start_x,segment.start_y,segment.end_x,segment.end_y,segment.amplitude,segment.cycles,progress,segment.phase);
                break;
            case BONE_PATH_KIND.BEZIER:
                point=Trajectory_Bezier(segment.points,progress);
                break;
            case BONE_PATH_KIND.CUSTOM:
                point=segment.position_function(progress,sequence.start_x,sequence.start_y,sequence.bone,sequence,segment);
                break;
        }

        Trajectory_Apply(sequence.bone,point);
        sequence.bone.angle=sequence.start_angle+segment.spin*progress;
        sequence.bone._angle=sequence.bone.angle;
        if(!is_undefined(segment.length_to)) sequence.bone.length=lerp(sequence.start_length,segment.length_to,progress);
        if(segment.kind==BONE_PATH_KIND.CUSTOM&&!is_undefined(segment.step_function)) segment.step_function(progress,sequence.start_x,sequence.start_y,sequence.bone,sequence,segment);

        if(raw_progress<1){
            keep_advancing=false;
        }else{
            remaining=max(0,sequence.segment_time-segment.duration);
            sequence.segment_time=0;
            sequence.segment_started=false;
            sequence.segment_index++;
            if(sequence.segment_index>=segment_count){
                if(sequence.loop){
                    sequence.segment_index=0;
                }else{
                    sequence.finished=true;
                    if(sequence.destroy_on_finish&&instance_exists(sequence.bone)) instance_destroy(sequence.bone);
                }
            }
            if(remaining<=0) keep_advancing=false;
        }
    }
    return !sequence.finished;
}
