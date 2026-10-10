///@arg item_name
function Item_GetTextEat() {
	var NAME=argument[0];

	var result="";
	result+="{define `ITEM` `"+NAME+"`}";
	result+="* 你吃掉了{insert ITEM}。";

	return result;


}
