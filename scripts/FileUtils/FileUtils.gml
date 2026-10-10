// Try read all text from a file.
// Returns undefined if the file fails to load.
function File_ReadAllText(path){
	var file=file_text_open_read(path);
	if(file==-1){
		return undefined;
	}
	
	var text="";
	while(!file_text_eof(file)){
		text+=file_text_readln(file);
	}
	file_text_close(file);
	return text;
}

// Try write all text into a file.
// Returns true or false to indicate whether the operation is successful.
function File_WriteAllText(path, text){
	var file=file_text_open_write(path);
	if(file==-1){
		return false;
	}
	file_text_write_string(file,text);
	file_text_close(file);
	return true;
}

// Append one self-contained record without rewriting the existing file.
// Runtime recovery uses this for its incremental edit journal; formal saves
// still use File_WriteAllText and remain ordinary standalone JSON.
function File_AppendLine(path,text){
	var file=file_text_open_append(path);
	if(file==-1) return false;
	file_text_write_string(file,string(text));
	file_text_writeln(file);
	file_text_close(file);
	return true;
}
