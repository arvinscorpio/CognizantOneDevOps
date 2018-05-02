var fs = require('fs')

function getworkflow(callback) {
	console.log("In reading json");
 
 var jsonobj = '';
 if(!jsonobj){
 jsonobj = JSON.parse(fs.readFileSync('./workflow.json', 'utf8'));
 
 callback(null,jsonobj,null);
 }
 else{
 
 callback(null,null,"error in reading file");
}
}
module.exports = {
  getworkflow_coffee: getworkflow	// MAIN FUNCTION
  
}