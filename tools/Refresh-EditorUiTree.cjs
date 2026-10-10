// Documentation only. Run from the project root with Node.js.
// Uses the existing audited tree for hand-drawn pages and GML metadata for
// Workspace schemas. It never loads/saves a battle or launches the runtime.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const documentArg=process.argv.indexOf('--document');
const file = documentArg>=0?path.resolve(process.argv[documentArg+1]):path.join(root, 'docs/EDITOR_UI_STRUCTURE.md');
const core = fs.readFileSync(path.join(root, 'scripts/BattleEditor_Core/BattleEditor_Core.gml'), 'utf8');
const original = fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n');
function source(name) {
  const start = core.indexOf('function BattleEditor_' + name + '(');
  assert(start >= 0, name);
  const next = core.indexOf('\nfunction ', start + 1);
  return core.slice(start, next < 0 ? undefined : next);
}
// Evaluate only explicit, side-effect-free metadata functions, not game code.
const ctx = vm.createContext({
  clamp:(x,a,b)=>Math.max(a,Math.min(b,x)), round:Math.round, real:Number, string:String,
  array_length:a=>a.length, array_push:(a,...v)=>a.push(...v), array_insert:(a,i,v)=>a.splice(i,0,v),
  string_pos:(x,s)=>s.indexOf(x)+1, string_trim:s=>s.trim(), string_length:s=>s.length,
  string_split:(s,d)=>s.split(d), is_struct:x=>x!==null&&typeof x==='object',
  is_undefined:x=>x===undefined, struct_exists:(x,k)=>Object.hasOwn(x,k),
  variable_global_exists:()=>true, global:{battle_editor_project_runtime:{resources:{gb_styles:[{}]}}},
  BATTLE_EDITOR_LAYER:{IN_BOARD:0,OUTSIDE:1,BELOW_BOARD:2},
});
const functions = ['ObjectPaletteCategoryName','WorkspaceCreateOptions','WorkspaceCreateField','WorkspaceCreateFields',
  'SolidBoneFieldKeys','SolidBoneFieldLabels','ControlPropertiesAllForTypeBase','ControlPropertiesAllForType',
  'ControlPropertiesAllForStep','ControlPropertyCategory','ControlPropertyCategoryName','ControlPropertyName',
  'TargetTypeName','ControlCategoryForType','ControlCategoryName','ControlCategories','ControlGroupName',
  'ControlStepUsesDuration','IsBooleanControlProperty','IsChoiceControlProperty','ControlChoiceCount',
  'ControlChoiceCaption','MaskColorName','LayerName','WaveRotationModeName','SoulModeName','BlueDirectionName',
  'BoneStyleName','BuiltinActionOptions','ScreenActionOptions','ActionParameterKind','ActionParameterChoiceCount',
  'ActionParameterChoiceCaption','SolidBoneShapeName','DamageTypeName','BuiltinActionUsesTemplate',
  'ValueProperties','ValuePropertyName','AimBehaviorName','BoneAimBehaviorName'];
for (const f of functions) vm.runInContext(source(f), ctx, {timeout:1000,filename:f});
const call = (name,...args)=>ctx['BattleEditor_'+name](...args);
const N = (label, children=[])=>({label,children:children.map(x=>typeof x==='string'?N(x):x)});
const branch = (label, children)=>N(label+'{',children);
const option = (label, children=[])=>N(label+'/',children);
const list = (label, values)=>N(label+'['+values.join(',')+']');
const toggle = label=>N(label+'（开关：关 / 开）');
const input = label=>N(label+'()');
const tween = label=>list(label,['线性','正弦','二次','三次','四次','五次','指数','圆弧','回退','弹性','弹跳']);
const ease = label=>list(label,['渐入','渐出','渐入渐出']);
const timing=()=>[input('时长（帧）'),tween('Tween'),ease('Ease')];
const colors=Array.from({length:9},(_,i)=>call('DamageTypeName',i));
const visualColors=['白色','电蓝色','橙色','亮绿色','黄色','深绿色','红色','紫色','深蓝色'];
const targets=['玩家','主框','初始化的加框与减框','每个敌人','当前编辑回合的场景对象（动态：按 UID）'];
const frames=['主框','当前项目的每个加框与减框（动态：按 UID）'];
const audio=()=>N('音效',[list('此项目执行音效',['项目实际 snd... 资源','当前存档导入音频']),N('播放 / 停止（同一按钮切换）'),list('播放时机',['步骤执行时','步骤执行结束时']),toggle('启用这个项目的音效')]);
const visual=()=>branch('固定模板（勾选框）',[option('勾选',[list('颜色模板',visualColors)]),option('取消勾选',[N('自由调色板')])]);

// Parse the legacy ASCII tree structurally; closing braces are generated anew.
const treeText=original.split('```text\n')[1].split('\n```')[0];
let tree=N('游戏'), stack=[tree];
for(const line of treeText.split('\n').slice(1)){
  const m=line.match(/^([ |]*)(?:\|--|`--) (.*)$/);
  if(!m) continue;
  const depth=m[1].length/4+1;
  assert(Number.isInteger(depth),line);
  const node=N(m[2]);
  assert(stack[depth-1],line);
  stack[depth-1].children.push(node);stack[depth]=node;stack.length=depth+1;
}
function find(node,label){
  if(node.label===label)return node;
  for(const child of node.children){const found=find(child,label);if(found)return found;}
}
const editor=tree.children[0];
tree.children=tree.children.filter(n=>n.label!=='游戏设置');
tree.children.push(N('游戏设置',[
  toggle('调试模式'),toggle('简单模式'),toggle('特效'),toggle('高级特效'),toggle('显示 FPS'),toggle('神秘选项'),
  list('窗口缩放（左右键 / Z 切换）',['100%','125%','150%','175%','200%','适应屏幕']),
  N('保持画面比例与逻辑坐标；记住设置；超出屏幕自动适配；F4 全屏独立'),
  list('战斗读取存档（左右键 / Z 切换）',['当前实际存档文件夹（动态）']),N('X / Shift 返回')
]));
const workspace=find(tree,'脚本 Workspace');
const inspector=find(workspace,'列表项目 Inspector');
assert(inspector);
// Workspace creation comes from the persistent left palette, never the
// context menu. Keep these interaction nodes idempotent across regeneration.
const headedList=find(workspace,'列表');
assert(headedList);
workspace.children=[
  N('进入与收起',['点击脚本直接进入 Workspace，隐藏顶栏及其点击区域','Esc 收起后显示场景和顶栏，仍选中脚本','再次 Esc 恢复选中项目及画布平移、缩放；切到其他标签后不再触发此切换','输入框、下拉、拖放和连接优先取消，一次 Esc 只处理一层']),
  N('绘制与交互层级', ['网格（最底层；空白拖动平移）','函数轨迹预览（网格上、节点下）','节点连接线（贝塞尔曲线）','Workspace 列表与项目（连接处无分隔边，整串圆角外框）','原有外边框按循环范围着色（不叠框、不改内部分界，文字颜色独立）','Inspector（圆角暗色属性面板；保持整体滑入）','积木侧栏与拖放预览','顶栏（Workspace 收起时才显示；可见时最后绘制）']),
  N('积木侧栏（左侧，可收起）',[
    N('箭头图标（展开 / 收起；整个面板缓动滑入 / 滑出）'),
    N('事件头', ['游戏开始','怪物回合','计时器','玩家受伤','使用物品后','脚本入口','行动项目'].map(n=>N(n+'（拖到画布建立事件头，或接到游离串上方）'))),
    N('积木', ['控制对象','创建对象','内建攻击函数','画面 / 镜头 / 滤镜','播放音效','切换敌人贴图 / 动画','变量 / 公式','读取对象数值','条件判断','等待','循环范围','节点连接'].map(n=>N(n+'（拖到画布成为游离积木；拖到串中自动拼接）'))),
    N('滚轮翻动侧栏（不平移画布）')
  ]),
  N('右上角公式 ?',['再次点击收起；保留展开 / 收起动画','数学函数说明自动换行；底部文字包含在边框内','点击面板外关闭；不再占用初始化 / 脚本顶栏']),
  N('Workspace 操作',['空白拖动画布','Ctrl + 滚轮缩放','列表头拖动整串','从项目中间拖出该项及后续串','拖近拼接位置显示吸附线；松手提交','Esc / 右键取消拖放，原数据不变','节点连接端口拖到目标事件头左端口']),
  N('空白处右键选单',['贴上列表','贴上游离积木','显示 / 收起积木面板']),
  N('列表头右键选单',['复制整张列表','剪下整张列表','贴上整张列表','删除整张列表']),
  N('列表项目右键选单',['复制项目','剪下项目','贴到下方','删除项目','启用 / 禁用项目']),
  headedList,
  N('游离积木串',['没有事件头与运行按钮；不自动执行，也不能被节点连接启动','可编辑、保存、拆分、重接','拖入事件头以后使用同一套列表运行时']),
  inspector
];

function warning(property){return N('警告',[
  toggle('启用警告线'), input('警告帧数'),
  branch('朝向来源（切换按钮）',[option(property==='aim_motion'?'瞄准目标':'贴图方向'),option('自定义角度',[input('警告线角度')])])
]);}
function propertyNode(property,type){
  const label=call('ControlPropertyName',property,type);
  let fields=[];
  if(property==='position'){
    const board=type==='board';
    fields=[branch(board?'变换模式':'移动模式',(board?['目标状态','相对变化']:['目标位置','相对位移']).map((mode,i)=>option(mode,[
      input('X（空=不改）'),input('Y（空=不改）'),input(board?'角度':i?'角度位移（留空不控制）':'目标角度（留空不控制）'),
      ...(board?[input('宽度'),input('高度')]:[])
    ])))];
  }else if(property==='orbit') fields=[input('总旋转角度'),branch('中心（切换按钮）',[option('对象组中心'),option('自定义坐标',[input('中心 X'),input('中心 Y')])])];
  else if(property==='physics')fields=['移动方向','初始速度','加速度','弯曲角速','自转角速','时长（帧）'].map(input);
  else if(property==='aim_motion') fields=[list('瞄准目标',targets),branch('行为',Array.from({length:3},(_,i)=>option(call('AimBehaviorName',i),[
    list('方向更新',['执行时锁定一次','持续追踪目标']),...(i?[input('移动速度')]:[]),input('时长（帧）')
  ])))];
  else if(property==='shape')fields=[branch('目标形状',[option('矩形',[input('宽度'),input('高度')]),option('椭圆',[input('半径 X'),input('半径 Y')]),option('正三角形',[input('底边宽'),input('高度')]),option('多边形',[N('保留当前顶点（提示；此处无额外输入框）')])])];
  else if(property==='control_vertex')fields=[N('到战斗画面点选顶点'),N('已选顶点数量（只读）'),branch('坐标模式',[option('绝对位置',[input('目标 X'),input('目标 Y')]),option('相对位移',[input('位移 X'),input('位移 Y')])])];
  else if(property==='speak')fields=[N('编辑文本'),list('字体',['项目可用字体']),list('音色',['无声','默认文字音','打字机音','Sans','Toriel']),N('播放 / 停止'),list('气泡',['宽气泡・尖角向左','宽气泡・尖角向右','小气泡・尖角向左','小气泡・尖角向右','无框短句']),input('偏移 X'),input('偏移 Y'),list('推进',['自动打字并继续','Z / X 手动推进']),toggle('等待气泡结束再继续')];
  else if(property==='gb_hold')fields=[N('把待发射时间延长到 999 帧（说明）'),toggle('播放默认 GB 等待音效')];
  else if(property==='gb_release')fields=[N('结束等待并进入原有发射动画（无参数）')];
  else if(property==='follow')fields=[branch('跟随战斗框（勾选框）',[option('不跟随战斗框'),option('跟随战斗框',[list('目标框',frames)])])];
  else if(property==='soul_mode')fields=[branch('目标值',Array.from({length:7},(_,i)=>option(call('SoulModeName',i),i===1?[list('蓝魂方向',['上','下','左','右']),toggle('同时施加重力甩动')]:[])))];
  else if(['color','visual_color','color_frame'].includes(property))fields=[N('目标颜色（色块按钮，打开调色板）')];
  else if(call('IsBooleanControlProperty',property))fields=[toggle('目标值')];
  else if(call('IsChoiceControlProperty',property))fields=[list('目标值',Array.from({length:call('ControlChoiceCount',property)},(_,i)=>call('ControlChoiceCaption',property,i)))];
  else fields=[input(property==='player_name'?'目标文字':'目标值')];
  if(property==='damage_type')fields.push(toggle('同时修改显示颜色（关闭：只修改伤害判定）'));
  if(property==='mask_color')fields.push(N('当前遮罩颜色色块（预览）'));
  if(property==='length'&&type==='bone')fields.push(list('长度锚点',['中心','头端固定','尾端固定']));
  if(call('ControlStepUsesDuration',{kind:'control_object',property})&&!['physics','aim_motion'].includes(property))fields.push(...timing());
  if(['position','orbit','physics','aim_motion'].includes(property))fields.push(warning(property));
  return option(label,fields);
}
const typeKeys=[...source('ControlPropertiesAllForTypeBase').matchAll(/case "([^"]+)":return \[/g)].map(m=>m[1]);
const groupKinds=['bone_orbit','bone_wave','bone_corridor','bone_physics','bone_function_path','gb_pinwheel','bone_wall'];
function typeNode(type,kind=''){
  const properties=call('ControlPropertiesAllForStep',{target_type:type,target_group_kind:kind});
  const categories=new Map();
  for(const p of properties){const c=call('ControlPropertyCategory',p,type);if(!categories.has(c))categories.set(c,[]);categories.get(c).push(propertyNode(p,type));}
  return option(kind?call('ControlGroupName',kind):call('TargetTypeName',type),[
    branch('参数分类',[...categories].map(([category,props])=>option(call('ControlPropertyCategoryName',category),[branch('参数',props)])))
  ]);
}
function controlTargets(copy){
  const excluded=copy?['path_point','enemy','player_data','soul','hud_all','hud_name','hud_lv','hud_vitals','battle_buttons','button_fight','button_act','button_item','button_mercy']:[];
  return branch('目标分类',call('ControlCategories').flatMap(cat=>{
    const types=typeKeys.filter(t=>call('ControlCategoryForType',t)===cat&&!excluded.includes(t));
    if(!types.length)return [];
    return [option(call('ControlCategoryName',cat),[
      N(copy?'复制来源（动态：可复制场景对象；不含系统对象）':'控制目标（动态：系统对象、场景 Control ID、内建生成组与构造控制点）'),
      ...(copy?[input('副本 Control ID')]:[]),
      branch('所选目标类型（由目标决定）',types.map(t=>t==='path_point'?option('路径点',[branch('所属算法（由目标决定）',groupKinds.map(k=>typeNode(t,k))) ]):typeNode(t)))
    ])];
  }));
}
const control=option('控制对象',[branch('控制来源（按钮）',[option('控制原件',[controlTargets(false)]),option('复制后控制',[controlTargets(true)])]),audio()]);

const choiceValues={
  bone_style:['普通骨头','尖刺骨头'],bone_aim_behavior:['关闭指向','仅面朝目标','面朝并向目标移动'],aim_target:targets,follow_frame:frames,
  aim_update:['执行时锁定一次','持续追踪目标'],gb_style:['原版 UTE GB','当前存档自定义 GB 组（动态：仅存在自定义组时显示此控件）'],
  gb_spawn:['无（继承默认）','自定义坐标','画面中心','画面正上方外','画面右上角外','画面右方外','画面右下角外','画面正下方外','画面左下角外','画面左方外','画面左上方外','目标正上方','目标右上方','目标右方','目标右下方','目标正下方','目标左下方','目标左方','目标左上方'],
  fake:['真实 GB','假 GB 动画','假 GB 掉落'],tween:['线性','正弦','二次','三次','四次','五次','指数','圆弧','回退','弹性','弹跳'],ease:['渐入','渐出','渐入渐出'],
  gb_offset_direction:['自动：沿 GB 后方','自定义：绝对角度'],wave_rotation:['不旋转','持续转速','曲线转到目标角'],damage:colors,
  solid_shape:['立方体','正四面体','正八面体','正十二面体','正二十面体','四角锥'],platform_type:['紫色（不带玩家）','绿色（带玩家）'],
  font:['当前项目可用字体资源（动态）'],voice:['无声','默认文字音','打字机音','Sans','Toriel'],layer:['框内','框外','框下'],clip_mode:['全部框','自定义框']
};
function createFields(preset){
  if(preset.startsWith('board_'))return [input('Control ID'),input('中心 X'),input('中心 Y'),input('角度'),input('每帧旋转'),input('生命周期'),input('绘制深度'),branch('形状',[
    option('矩形',['上','下','左','右'].map(input)),option('椭圆',['椭圆半径 X','椭圆半径 Y'].map(input)),option('正三角形',[input('正三角形尺寸')]),
    option('多边形',[N('当前顶点 / 总数（只读）'),input('顶点 X'),input('顶点 Y'),N('上个'),N('下个'),N('新增'),N('删除')])
  ])];
  const result=[input('Control ID')];
  for(const f of call('WorkspaceCreateFields',preset)){
    if(f.path==='visual_tint.color'&&preset!=='decoration')continue;
    if(f.kind==='visual_template_toggle'){result.push(visual());continue;}
    if(f.kind==='choice'){assert(choiceValues[f.choice],f.choice);result.push(list(f.label,choiceValues[f.choice]));if(f.choice==='voice')result.push(N('播放 / 停止'));}
    else if(f.kind==='bool')result.push(toggle(f.label));
    else if(f.kind==='lifetime')result.push(branch(f.label,[option('本回合一直存在'),option('指定存活帧数',[input('存活帧数')])]));
    else if(f.kind==='color')result.push(N(f.label+'（调色板）'));
    else if(f.kind==='path')result.push(N(f.label,[input('路径'),N('选择')]));
    else if(f.kind==='frames')result.push(N(f.label,[input('当前帧路径'),N('选择'),N('<'),N('>'),N('+'),N('-'),N('当前帧 / 总帧（只读）')]));
    else if(f.kind==='clip_frames')result.push(N(f.label,[list('选择参与裁剪的框',frames),N('多选当前框（勾选框）')]));
    else result.push(input(f.label));
  }
  return result;
}
const create=option('创建对象',[branch('创建分类',Array.from({length:6},(_,i)=>option(call('ObjectPaletteCategoryName',i),[
  branch('对象',call('WorkspaceCreateOptions',i).map(p=>option(p.name,createFields(p.id))))
]))),audio()]);

function actionFields(action,scope='builtin'){
  return action.labels==='无参数'?[]:action.labels.split(';').map((label,i)=>{
    const kind=call('ActionParameterKind',scope,action.id,i);
    if(kind==='expression'||kind==='identifier')return input(label);
    if(kind==='boolean')return toggle(label);
    return list(label,Array.from({length:call('ActionParameterChoiceCount',kind)},(_,j)=>call('ActionParameterChoiceCaption',kind,j,action.id)));
  });
}
const template=()=>list('复制对象模板',['默认骨头','当前回合可实例化场景对象（不含 GB；不含系统对象）']);
const builtins=call('BuiltinActionOptions').map(a=>{
  let fields=[];
  if(a.id!=='board_shape')fields.push(toggle('跟随'));
  if(a.id==='bone_function_path')fields.push(toggle('轨迹预览'),branch('对象来源',[
    option('复制已有对象',[input('副本 Control ID'),list('复制哪个对象',['当前回合可复制且可移动对象（不含 GB、战斗框及系统对象）'])]),
    option('带动已有对象组',[list('已有对象组',['可移动系统对象及 Control ID 对象组（不含 GB、路径点；按类型和 ID 显示数量）'])])
  ]),...actionFields(a));
  else if(a.id==='bone_wall') fields.push(input('控制 ID'),branch('方向',['上','下','左','右','上下','左右','四个方向'].map((direction,i)=>option(direction,[
    template(),input(i<4?'目标 X':'中心 X'),input(i<4?'目标 Y':'中心 Y'),input('宽度'),input('间距'),input(i<4?'目标高度':'中心半径'),input('骨头长度'),input('进退速度'),input('停留帧'),list('颜色',colors),list('层级',choiceValues.layer),tween('进场曲线'),ease('进场缓动'),tween('退场曲线'),ease('退场缓动'),toggle('警告框'),input('警告帧数')
  ]))));
  else if(a.id==='board_shape')fields.push(list('目标控制 ID',frames),...actionFields(a),tween('曲线类型'),ease('缓动方向'));
  else if(a.id==='bone_orbit') fields.push(input('Control ID'),list('模板',['默认骨头','当前回合可实例化场景对象（不含 GB；不含系统对象）']),N('中心',[input('X'),input('Y')]),N('半径',[input('X'),input('Y')]),input('数量'),input('起始角'),input('转速'),input('朝向偏移'),input('长度'),list('颜色',colors),list('层级',choiceValues.layer),N('进场',[input('时间'),tween('曲线'),ease('缓动')]),input('维持（-1=回合）'),N('退场',[input('时间'),tween('曲线'),ease('缓动')]));
  else fields.push(input('控制 ID'),...(call('BuiltinActionUsesTemplate',a.id)?[template()]:[]),...actionFields(a));
  if(a.id!=='board_shape')fields.push(toggle('同时修改显示颜色（关闭：只修改伤害判定）'));
  fields.push(audio());
  return option(a.name,fields);
});
const builtin=option('内建攻击函数',[branch('内建攻击函数',builtins)]);
const screen=option('画面 / 镜头 / 滤镜',[branch('画面 / 镜头 / 滤镜动作',call('ScreenActionOptions').map(a=>option(a.name,[...actionFields(a,'screen'),...(a.id==='camera_set'?[tween('过渡曲线'),ease('缓动方向')]:[]),...(a.id==='screen_reset'?[N('无参数')]:[]),audio()]))) ]);

const valueSources=[['time','time','时间与回合'],['player','player_data','玩家数值'],['soul','soul','玩家灵魂'],['shield','shield','护盾'],
  ...['soul','board','enemy','bone','gb','slash','true_knife','bone_3d','bone_4d','platform','decoration','sprite_hazard','typewriter'].map(t=>['object',t,'所选'+call('TargetTypeName',t)+'（动态：具体对象 UID）'])];
const read=option('读取对象数值',[branch('数值来源',valueSources.map(([key,type,label])=>option(label,[list('读取属性',call('ValueProperties',key,type).map(p=>call('ValuePropertyName',p)))]))),input('命名为'),branch('名称检查（状态反馈，不是下拉）',[
  option('无冲突',[N('直接可用（提示）')]),option('格式错误',[N('重新命名')]),option('系统保留名称',[N('重新命名')]),option('已存在，未确认覆盖',[N('覆盖原变量'),N('重新命名')]),option('已确认覆盖',[N('撤销覆盖许可')])
]),audio()]);
const oldSteps=(find(inspector,'项目类型{')||inspector).children;
const retained=label=>{
  const node=oldSteps.find(n=>n.label.replace(/[\/{]$/,'')===label);
  assert(node,'Missing '+label);
  node.label=label+'/';return node;
};
const stepChoices=[control,create,builtin,screen,retained('播放音效'),retained('切换敌人贴图 / 动画'),retained('变量 / 公式'),read,retained('条件判断'),
  option('等待',[branch('等待方式',[option('固定帧数',[input('等待时长（帧）')]),option('等上一个步骤执行完',[input('完成后额外等待（帧）'),N('先等上一组并行步骤全部完成，再追加等待（提示）')])]),audio()]),
  option('循环范围',[input('重复次数 / 公式'),input('循环后续项目数'),input('每轮额外等待（帧）'),audio()]),
  option('节点连接',[N('拖右端口 > 列表头左端口'),audio()])];
inspector.children=[branch('项目类型',stepChoices),N('旧存档兼容显示',[N('旧脚本（已禁用）',[N('旧版任意 GML 脚本步骤已禁用；请选择内建攻击函数（提示）'),audio()])])];

// Fix stale scene-only controls without pretending the scene and Workspace
// inspectors are the same UI (their conditional visibility differs).
const scene=find(tree,'选中对象属性（新对象放置后 / 场景对象）');
for(const node of scene.children){
  if(['骨头','骨刺'].includes(node.label)){
    node.children=node.children.filter(n=>!['随 / 自','锁 / 颜色（旧的小颜色按钮）','指向：开 / 指向：关','持续更新 / 出生一次','追踪：开 / 追踪：关','追踪速度()','朝向目标的行为{'].includes(n.label)&&!n.label.startsWith('指向对象['));
    node.children.push(branch('朝向目标的行为',['关闭指向','仅面朝目标','面朝并向目标移动'].map((name,i)=>option(name,[list('指向对象',targets),list(i===0?'方向更新（启用后生效）':'更新方式',['执行时锁定一次','持续追踪目标']),...(i===2?[input('移动速度')]:[])]))));
  }
  const fixed=node.children.findIndex(n=>n.label==='固定模板[关,开]');
  if(fixed>=0){node.children[fixed]=visual();node.children=node.children.filter(n=>!n.label.startsWith('显示颜色{'));}
  node.children=node.children.filter(n=>n.label!=='跟随规则 / 自定义色');
  if(node.label==='GB'){
    const at=node.children.findIndex(n=>n.label.startsWith('退出方向模式'));
    assert(at>=0);
    node.children=node.children.filter(n=>!n.label.startsWith('退出方向模式')&&!['自定义退出方向（自动时隐藏）()','偏移初始速度()','每帧速度变化()','GB 本体旋转速度()'].includes(n.label)&&!n.label.startsWith('GB 贴图组['));
    node.children.splice(at,0,branch('退出方向模式',[
      option('自动：沿 GB 后方',[input('初始速度'),input('每帧速度变化'),input('GB 本体旋转速度')]),
      option('自定义：绝对角度',[input('退出方向'),input('初始速度'),input('每帧速度变化'),input('GB 本体旋转速度')])
    ]));
    node.children.push(list('GB 贴图组',['原版 UTE GB','当前存档自定义 GB 组（动态：仅存在自定义组时显示此控件）']));
  }
}
if(!scene.children.some(n=>n.label==='骨刺')){
  const index=scene.children.findIndex(n=>n.label==='骨头');
  const spike=structuredClone(scene.children[index]);spike.label='骨刺';scene.children.splice(index+1,0,spike);
}
const sceneTimeline=find(tree,'场景与时间轴');
if(!sceneTimeline.children.some(n=>n.label==='无对象选中时'))sceneTimeline.children.push(N('无对象选中时',[N('当前编辑回合 / 自动时长（只读）'),N('当前回合对象数量（只读）'),N('隐藏当前回合对象 / 显示当前回合对象')]));
const textModal=find(tree,'文本编辑弹层');
for(const node of textModal.children)if(node.label.startsWith('标题['))node.label=node.label.replace('标题[','标题（按打开入口显示，不是下拉）：').replace(/\]$/,'');

function expandInline(node){
  // Inline conditional blocks from the old document become real children.
  const m=node.label.match(/^([^{}]+)\{([^{}]+)\}$/);
  if(m&&m[2].includes(';')){
    node.label=m[1]+'{';
    node.children=m[2].split(';').map(x=>{const i=x.indexOf('/');return option(x.slice(0,i),i<0?[]:splitControls(x.slice(i+1)).map(s=>N(s)));});
  }
  node.children.forEach(expandInline);
}
function splitControls(s){let depth=0,start=0,result=[];for(let i=0;i<s.length;i++){if('([{'.includes(s[i]))depth++;if(')]}'.includes(s[i]))depth--;if(s[i]===','&&!depth){result.push(s.slice(start,i));start=i+1;}}if(s.slice(start))result.push(s.slice(start));return result;}
expandInline(tree);
const helpSource=source('HelpSections');
const help=[...helpSource.matchAll(/\{title:("(?:\\.|[^"\\])*"),body:("(?:\\.|[^"\\])*"?)\}/g)].map(m=>({title:JSON.parse(m[1]),body:JSON.parse(m[2])}));
assert.equal(help.length,12,'Teaching extraction must capture every source chapter');
const tutorial=find(tree,'教学');
tutorial.children=[N('目录（章节按钮）',help.map((h,i)=>N((i+1)+'. '+h.title))),N('滚轮阅读'),N('回到目录')];
function render(node,prefix='',last=true,rootNode=false){
  let out=(rootNode?'':prefix+(last?'`-- ':'|-- '))+node.label+'\n';
  const childPrefix=rootNode?'':prefix+(last?'    ':'|   ');
  node.children.forEach((n,i)=>{out+=render(n,childPrefix,i===node.children.length-1);});
  if(node.label.endsWith('{'))out+=childPrefix+'}\n';
  return out;
}
// Tree root's only child must remain flush left, matching a filesystem tree.
let output='# 战斗弹幕编辑器 UI 文件树\n\n核对日期：2026-09-28。以当前源码实际绘制与选项元数据为准；不是功能愿望清单，也不代表已逐项运行验证。\n\n'+
  '表示规则：\n\n- `名称`：按钮；非按钮的分组、提示和只读内容另行标明。\n- `名称()`：输入框。\n- `名称[选项一,选项二]`：普通下拉。\n- `名称{` 内的 `选项/`：选择后改变下方界面的分支；依赖控件写在分支内。开关或自动状态分支会注明，不冒充下拉。\n- 动态选项注明数据来源；具体存档的对象名、资源名不是固定菜单，不能穷举为所有项目通用选项。\n- 重复分支照样展开；数值单位和“仅在某条件下出现”按现有界面保留。\n\n```text\n'+render(tree,'',true,true)+'```\n\n## 教学标签页原文\n\n以下标题和正文直接提取自 `BattleEditor_HelpSections()`，不改写、不摘要。\n';
for(let i=0;i<help.length;i++)output+='\n### '+(i+1)+'. '+help[i].title+'\n\n'+help[i].body+'\n';
output+='\n## 核对范围\n\n- 初始化、场景属性、存档、共用弹层：保留既有逐项结构，对照当前 Draw / Step 更新变动入口。\n- Workspace：包括左侧积木栏、事件头、游离串与拖放拼接；按当前能力表重建控制分支、创建字段与内建动作参数。\n- 右键菜单：场景、Workspace 空白处、列表头、列表项目、公式输入框分别列出。\n- 此生成工具只改文档，不改存档或 data.win。源码验证及 Runner 回归证据见 docs/WORKSPACE_DRAG_BATCH.md；此结构树不代表逐页视觉验收。\n';
assert(output.includes('完成后额外等待（帧）()'));
assert(output.includes('轨迹半径 X/'));
assert(output.includes('朝向 / 追踪目标/'));
assert.equal((output.match(/^```/gm)||[]).length,2);
assert(!output.includes('position/'));
for(const h of help)assert(output.includes(h.body));
if(process.argv.includes('--check')){
  if(output!==original){let i=0;while(output[i]===original[i])i++;throw new Error('Tree differs at character '+i+': '+JSON.stringify(output.slice(i,i+160)));}
}
else fs.writeFileSync(file,output,'utf8');
console.log(JSON.stringify({file,lines:output.split('\n').length,bytes:Buffer.byteLength(output),chapters:help.length,controlTypes:typeKeys.length,builtinActions:builtins.length,createPresets:Array.from({length:6},(_,i)=>call('WorkspaceCreateOptions',i).length).reduce((a,b)=>a+b),mode:process.argv.includes('--check')?'verified':'written'}));
