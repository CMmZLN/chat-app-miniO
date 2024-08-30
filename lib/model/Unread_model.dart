class Un_Thread {
  int? id;
  String? name;
  String? directthreadmsg;
  String? created_at;
  bool? draftStatus;
  List<dynamic>? files;
  List<dynamic>? fileNames;
  String? profileImage;
  Un_Thread(
      {this.id,
      this.directthreadmsg,
      this.name,
      this.created_at,
      this.files,
      this.fileNames,
      this.profileImage,
      this.draftStatus});
  Un_Thread.fromJson(Map<String, dynamic> json) {
    id = json["threadid"];
    name = json['name'];
    directthreadmsg = json['directthreadmsg'];
    created_at = json['created_at'];
    files = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];
    draftStatus = json['draft_message_status'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["threadid"] = this.id;
    data['created_at'] = this.created_at;
    data['directthreadmsg'] = this.directthreadmsg;
    data['name'] = this.name;
    data['file_urls'] = this.files;
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    data['draft_message_status'] = this.draftStatus;
    return data;
  }
}

class Un_G_Thread {
  int? id;
  String? name;
  String? channel_name;
  String? groupthreadmsg;
  bool? draftStatus;
  String? created_at;
  List<dynamic>? files;
  List<dynamic>? fileNames;
  String? profileImage;

  Un_G_Thread(
      {this.id,
      this.groupthreadmsg,
      this.channel_name,
      this.name,
      this.created_at,
      this.files,
      this.fileNames,
      this.profileImage,
      this.draftStatus});
  Un_G_Thread.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    channel_name = json['channel_name'];
    groupthreadmsg = json['groupthreadmsg'];
    files = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];
    created_at = json['created_at'];
    draftStatus = json['draft_message_status'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['created_at'] = this.created_at;
    data['groupthreadmsg'] = this.groupthreadmsg;
    data['name'] = this.name;
    data['channel_name'] = this.channel_name;
    data['file_urls'] = this.files;
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    data['draft_message_status'] = this.draftStatus;
    return data;
  }
}

class Un_DirectMsg {
  int? id;
  String? created_at;
  String? directmsg;
  String? name;
  List<dynamic>? files;
  List<dynamic>? fileNames;
  bool? draftStatus;
  String? profileImage;
  Un_DirectMsg(
      {this.id,
      this.created_at,
      this.directmsg,
      this.name,
      this.files,
      this.fileNames,
      this.profileImage,
      this.draftStatus});
  Un_DirectMsg.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    created_at = json['created_at'];
    directmsg = json['directmsg'];
    draftStatus = json['draft_message_status'];
    files = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];
    name = json['name'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = this.id;
    data['created_at'] = this.created_at;
    data['directmsg'] = this.directmsg;
    data['name'] = this.name;
    data['file_urls'] = this.files;
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    data['draft_message_status'] = this.draftStatus;
    return data;
  }
}

class Un_G_message {
  int? id;
  String? name;
  String? channel_name;
  String? groupmsg;
  bool? draftStatus;
  String? created_at;
  List<dynamic>? files;
  List<dynamic>? fileNames;
  String? profileImage;

  Un_G_message(
      {this.id,
      this.channel_name,
      this.created_at,
      this.groupmsg,
      this.name,
      this.files,
      this.fileNames,
      this.profileImage,
      this.draftStatus});
  Un_G_message.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    groupmsg = json['groupmsg'];
    created_at = json['created_at'];
    channel_name = json['channel_name'];
    files = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];
    draftStatus = json['draft_message_status'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['groupmsg'] = this.groupmsg;
    data['created_at'] = this.created_at;
    data['channel_name'] = this.channel_name;
    data['file_urls'] = this.files;
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    data['draft_message_status'] = this.draftStatus;
    return data;
  }
}
