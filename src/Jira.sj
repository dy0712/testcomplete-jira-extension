//USEUNIT JiraIssueData

/*Ed*/ var umsg_ConnectFail = "Failed to access %s: %s";
/*Ed*/ var umsg_OpenConnectFail = "Failed to open a connection to the server '%s'.\r\nDetails: %s";
/*Ed*/ var umsg_OpenConnectFailWithUnknownError = "Failed to open a connection to the server '%s'.\r\nMost probably, the server name is invalid.";
/*Ed*/ var umsg_ServerFail = "The server %s returned an error with code %d: \r\n%s";
/*Ed*/ var umsg_MissingProject = "A project with the key '%s' was not found.";
/*Ed*/ var umsg_MissingField = "The 'Bug' issue type has no '%s' field.";
/*Ed*/ var umsg_MissingIssueType = "The project with the key '%s' does not have the '%s' issue type. Please add this issue type to the project or use another project.";
/*EZ*/ var umsg_FileDoesNotExist = "The '%s' file does not exist.";
/*Ed*/ var umsg_EmptyServerUrl = "Invalid Jira server URL.";

var jiraConnection = {

  m_serverUrl: "",
  m_JiraUser: "",
  m_JiraPassword: "",
  m_xmlhttp: new ActiveXObject("MSXML2.ServerXMLHTTP"),

  throwError: function (errorMessage) {
    throw {
      error: errorMessage
    };
  },

  createAuthHeaderData: function (request) {
    var authData = aqObject.encodeBase64(this.m_JiraUser + ":" + this.m_JiraPassword);
    return aqString.Format("Basic %s", authData);
  },

  processResponseError: function (responseText) {
    try {
      var errorMessage = "";
      var resp = eval('(' + responseText + ')');

      if (resp.hasOwnProperty("errorMessages") && (resp.errorMessages.length > 0)) {
        for (var i = 0; i < resp.errorMessages.length; i++) {
          errorMessage += resp.errorMessages[i] + "\n";
        }
      } else if (resp.hasOwnProperty("errors") && (resp.errors.length > 0)) {
        for (var i = 0; i < resp.errors.length; i++) {
          errorMessage += resp.errors[i] + "\n";
        }
      } else if (resp.hasOwnProperty("errors")) {
        for (var field in resp.errors) {
          errorMessage += field + " : " + resp.errors[field] + "\n";
        }
      }

      if (errorMessage != "") {
        return errorMessage;
      } else {
        return responseText;
      }
    } catch (e) {
      return responseText;
    }
  },

  postRequest: function (operation, url, data, expectedResult) {
    try {
      this.m_xmlhttp.open(operation, url, false);
    } catch (e) {
      if (e.message == "")
        this.throwError(aqString.Format(umsg_OpenConnectFailWithUnknownError, this.m_serverUrl));
      else
        this.throwError(aqString.Format(umsg_OpenConnectFail, this.m_serverUrl, e.message));
    }

    this.m_xmlhttp.setRequestHeader("Authorization", this.createAuthHeaderData());
    this.m_xmlhttp.setRequestHeader("Content-type", "multipart/form-data");
    this.m_xmlhttp.setRequestHeader("Content-length", data.length);
    this.m_xmlhttp.setRequestHeader("Accept", "image/*, multipart/form-data; q=0.9, */*; q=0.8");
    this.m_xmlhttp.setRequestHeader("Accept-Charset", "UTF-8, *;q=0.8");

    try {
      this.m_xmlhttp.send(data);
    } catch (e) {
      this.throwError(aqString.Format(umsg_ConnectFail, this.m_serverUrl, e.message));
    }

    if (this.m_xmlhttp.status != expectedResult) {
      this.throwError(aqString.Format(umsg_ServerFail, this.m_serverUrl, this.m_xmlhttp.status, this.processResponseError(this.m_xmlhttp.responseText)));
    }

    if (this.m_xmlhttp.responseText !== "") {
      var resp = eval('(' + this.m_xmlhttp.responseText + ')');
      if (resp.hasOwnProperty("error") && (resp.error != null))
        this.throwError(resp.error);

      return resp;
    } else {
      return {};
    }
  },

  reset: function () {
    this.m_JiraUser = "";
    this.m_JiraPassword = "";
    this.m_serverUrl = "";
  },

  authorize: function (url, user, password) {
    this.reset();
	
	if (!url || 0 === url.length) {
	  return {error : umsg_EmptyServerUrl};
	}

    var newUrl = url;

    var index = aqString.FindLast(newUrl, "/", false)
    var len = aqString.GetLength(newUrl);

    if (index == (len - 1)) {
      newUrl = aqString.Remove(newUrl, index, 1);
    }

    if (aqString.Find(newUrl, "http", 0, false) == -1) {
      newUrl = "http://" + newUrl;
    }

    this.m_JiraUser = user;
    this.m_JiraPassword = password;

    try {
      // Check connection
      this.postRequest("GET", newUrl + "/rest/api/2/issue/createmeta", "", 200);

      this.m_serverUrl = newUrl;
      return {};
    } catch (e) {
      this.reset();

	  if (e.hasOwnProperty("error")) {
	    return e;
	  } else {
	    return {error : e};
	  }
    }
  },

  retrieveProjectMeta: function (projectKey) {
    var url = this.m_serverUrl + "/rest/api/2/issue/createmeta?expand=projects.issuetypes.fields";
    var metaData = this.postRequest("GET", url, "", 200);

    for (var i = 0; i < metaData.projects.length; i++) {
      if (metaData.projects[i].key == projectKey) {
        return metaData.projects[i];
      }
    }

    this.throwError(aqString.Format(umsg_MissingProject, projectKey));
  },

  retrieveIssueTypeMeta: function (projectMeta, issueTypeName) {
    for (var i = 0; i < projectMeta.issuetypes.length; i++) {
      var issueType = projectMeta.issuetypes[i];

      if (issueType.name == issueTypeName) {
        return issueType;
      }
    }

    this.throwError(aqString.Format(umsg_MissingIssueType, projectMeta.key, issueTypeName));
  },

  checkRequiredField: function (issue, fieldName) {
    if (!issue.fields.hasOwnProperty(fieldName)) {
      this.throwError(aqString.Format(umsg_MissingField, fieldName));
    }
  },

  mergeIssueDataFields: function (dataObject, issueTypeMeta, issueData) {
    var result = dataObject;
    var fieldValues = issueData.get_fieldValues();

    for (var name in fieldValues) {
      if (!fieldValues.hasOwnProperty(name)) {
        continue;
      }

      if ((fieldValues[name] === null) || (fieldValues[name] === undefined)) {
        continue;
      }

      this.checkRequiredField(issueTypeMeta, name);

      result.fields[name] = fieldValues[name];
    }

    return result;
  },

  createIssue: function (issueData) {
    try {
      var projectMeta = this.retrieveProjectMeta(issueData.get_projectKey());
      var issueTypeMeta = this.retrieveIssueTypeMeta(projectMeta, issueData.get_issueType());

      var dataObject = {
        fields: {
          project: {
            id: projectMeta.id
          },
          issuetype: {
            id: issueTypeMeta.id
          }
        }
      };

      dataObject = this.mergeIssueDataFields(dataObject, issueTypeMeta, issueData);
      return this.postRequest("POST", this.m_serverUrl + "/rest/api/2/issue", JSON.stringify(dataObject), 201);
    } catch (e) {
      if (e.hasOwnProperty("error")) {
	    return e;
	  } else {
	    return {error : e};
	  }
    }
  },

  updateIssue: function (issueKey, issueData) {
    try {
      var dataObject = {
        fields: issueData.get_fieldValues()
      };

      return this.postRequest("PUT", this.m_serverUrl + "/rest/api/2/issue/" + issueKey, JSON.stringify(dataObject), 204);
    } catch (e) {
	  if (e.hasOwnProperty("error")) {
	    return e;
	  } else {
	    return {error : e};
	  }
    }
  },

  createAttachment: function (issueKey, attachmentFileName) {
    try {
      var multipart_boundary = "----TestComplete5a9743bff0d1415723467";

      if (!aqFile.Exists(attachmentFileName)) {
        this.throwError(aqString.Format(umsg_FileDoesNotExist, attachmentFileName));
      }

      try {
        this.m_xmlhttp.open("POST", this.m_serverUrl + "/rest/api/2/issue/" + issueKey + "/attachments", false);
      } catch (e) {
        if (e.message === "") {
          this.throwError(aqString.Format(umsg_OpenConnectFailWithUnknownError, this.m_serverUrl));
        } else {
          this.throwError(aqString.Format(umsg_OpenConnectFail, this.m_serverUrl, e.message));
        }
      }

      var fileName = aqFileSystem.GetFileName(attachmentFileName);
      var data = "--" + multipart_boundary + "\r\nContent-Disposition: form-data; name=\"file\"; filename=\"" +
        fileName + "\"\r\nContent-Type: multipart/form-data\r\nContent-Transfer-Encoding: base64\r\n\r\n";

      data += aqFile.ReadWholeTextFile(attachmentFileName, aqFile.ctANSI);
      data += "\r\n--" + multipart_boundary + "--\r\n";

      this.m_xmlhttp.setRequestHeader("Authorization", this.createAuthHeaderData());
      this.m_xmlhttp.setRequestHeader("X-Atlassian-Token", "nocheck");
      this.m_xmlhttp.setRequestHeader("Content-Length", data.length);
      this.m_xmlhttp.setRequestHeader("Content-Type", aqString.Format("multipart/form-data; boundary=%s", multipart_boundary));

      try {
        this.m_xmlhttp.send(data);
      } catch (e) {
        this.throwError(aqString.Format(umsg_ConnectFail, this.m_serverUrl, e.message));
      }

      if (this.m_xmlhttp.status != 200) {
        this.throwError(aqString.Format(umsg_ServerFail, this.m_serverUrl, this.m_xmlhttp.status, this.processResponseError(this.m_xmlhttp.responseText)));
      }

      if (this.m_xmlhttp.responseText != "") {
        var response = eval('(' + this.m_xmlhttp.responseText + ')');
        if (response.error != null) {
          this.throwError(response.error);
        }

        return response;
      } else {
        return {};
      }
    } catch (e) {
      if (e.hasOwnProperty("error")) {
	    return e;
	  } else {
	    return {error : e};
	  }
    }
  }
}
