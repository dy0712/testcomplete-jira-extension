var srcDir = "src";
var outDir = "out";
var srcFiles = ["Jira.sj", "JiraIssueData.sj", "JiraRTO.sj"];
var additionalFiles = ["Description.xml", "jira_helpers.vbs"];
var outFileName = "JiraSupport";

// Evaluate paths
var fso = new ActiveXObject("Scripting.FileSystemObject");
var currDir = fso.GetAbsolutePathName(".");
var srcPath = currDir + "\\" + srcDir;
var zipFileDir = currDir + "\\" + outDir;
var unpackedFileDir = zipFileDir + "\\" + "unpacked";
var zipFilePath = zipFileDir + "\\" + outFileName + ".zip";
var extFilePath = zipFileDir + "\\" + outFileName + ".tcx";

// Delete the output folder, if it exists
if (fso.FolderExists(zipFileDir)) {
  WScript.Echo("Deleting old files, please wait...");
  fso.DeleteFolder(zipFileDir);
  WScript.Sleep(1000);
}

// Create the output folders
fso.CreateFolder(zipFileDir);
fso.CreateFolder(unpackedFileDir);

// Merge sources
var generatedScriptFile = fso.CreateTextFile(unpackedFileDir + "\\" + outFileName + ".js", true, false);
for (var i = 0; i < srcFiles.length; i++) {
  var file = fso.OpenTextFile(srcPath + "\\" + srcFiles[i], 1);
  var contents = file.ReadAll();
  file.Close();
  generatedScriptFile.Write(contents);
}
generatedScriptFile.Close();

// Copy additional files
for (var i = 0; i < additionalFiles.length; i++) {
  fso.CopyFile(currDir + "\\" + additionalFiles[i], unpackedFileDir + "\\");
}

// Create an empty .zip file
var zipFile = fso.CreateTextFile(zipFilePath, true, false);
var emptyZipContent = "PK" + String.fromCharCode(5, 6);
for (var i = 0; i < 18; i++) {
  emptyZipContent += String.fromCharCode(0);
}
zipFile.Write(emptyZipContent);
zipFile.Close();

// Copy unpacked files to the .zip archive
var shapp = new ActiveXObject("Shell.Application");
var sources = shapp.NameSpace(unpackedFileDir).Items();
shapp.NameSpace(zipFilePath).CopyHere(sources);

WScript.Echo("Packing files, please wait...");
WScript.Sleep(1000);

// Rename .zip to .tcx
fso.MoveFile(zipFilePath, extFilePath);

WScript.Echo("Ready!");
WScript.Echo("Script extension file: " + extFilePath);