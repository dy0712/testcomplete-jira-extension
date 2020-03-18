//USEUNIT Jira
//USEUNIT JiraIssueData

function RTO_CheckResult(result)
{
  if (result.hasOwnProperty("error")) {
    Log.Error(result.error || "An error occured.");
	return false;
  } else {
    return true;
  }
}

function RTO_Login(url, login, password) {
  var result = jiraConnection.authorize(url, login, password);
  return RTO_CheckResult(result);
}

function RTO_CreateNewBugData(projectKey, assignee, priority, summary, description) {
  var result = new NewIssueData(projectKey, "Bug");

  result.setField("assignee", {
    name: assignee
  });
  result.setField("priority", {
    name: priority
  });
  result.setField("summary", summary);
  result.setField("description", description);

  return result;
}

function RTO_CreateNewIssueData(projectKey, issueType) {
  return new NewIssueData(projectKey, issueType);
}

function RTO_CreateUpdateIssueData() {
  return new UpdateIssueData();
}

function RTO_PostIssue(newIssueData) {
  var result = jiraConnection.createIssue(newIssueData);
  if (RTO_CheckResult(result)) {
    return result.key;
  } else {
    return "";
  }
}

function RTO_UpdateIssue(issueKey, updateIssueData) {
  var result = jiraConnection.updateIssue(issueKey, updateIssueData);
  return RTO_CheckResult(result);
}

function RTO_PostAttachment(issueKey, fileName) {
  var result = jiraConnection.createAttachment(issueKey, fileName);
  return RTO_CheckResult(result);
}
