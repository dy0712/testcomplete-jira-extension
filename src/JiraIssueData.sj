function NewIssueData(projectKey, issueType) {
  var fieldValues = {};

  this.get_projectKey = function () {
    return projectKey;
  };

  this.get_issueType = function () {
    return issueType;
  };

  this.get_fieldValues = function () {
    return fieldValues;
  };

  this.setField = function (name, value) {
    fieldValues[name] = value;
    return this;
  };

  this.setFieldJSON = function (name, json) {
    fieldValues[name] = JSON.parse(json);
    return this;
  };
}

function UpdateIssueData() {
  var fieldValues = {};

  this.get_fieldValues = function () {
    return fieldValues;
  };

  this.setField = function (name, value) {
    fieldValues[name] = value;
    return this;
  };

  this.setFieldJSON = function (name, json) {
    fieldValues[name] = JSON.parse(json);
    return this;
  };
}
