class SessionData {
  MWorkspace? mWorkspace;
  List<MUsers>? mUsers;
  CurrentUser? currentUser;
  List<MChannels>? mChannels;
  List<MPChannels>? mPChannels;
  List<int>? directMsgcounts;
  int? allUnreadCount;
  List<int>? mChannelsids;
  List<TDirectDraft>? tDirectDraft;
  List<TDirectThreadDraft>? tDirectThreadDraft;
  List<TGroupDraft>? tGroupDraft;
  List<TGroupThreadsDraft>? tGroupThreadsDraft;
  List<int>? groupDraftCounts;
  List<int>? directDraftCounts;

  SessionData(
      {this.mWorkspace,
      this.mUsers,
      this.currentUser,
      this.mChannels,
      this.mPChannels,
      this.directMsgcounts,
      this.allUnreadCount,
      this.mChannelsids});

  SessionData.fromJson(Map<String, dynamic> json) {
    mWorkspace = json['m_workspace'] != null
        ? new MWorkspace.fromJson(json['m_workspace'])
        : null;
    if (json['m_users'] != null) {
      mUsers = <MUsers>[];
      json['m_users'].forEach((v) {
        mUsers!.add(new MUsers.fromJson(v));
      });
    }
    currentUser = json['current_user'] != null
        ? new CurrentUser.fromJson(json['current_user'])
        : null;
    if (json['m_channels'] != null) {
      mChannels = <MChannels>[];
      json['m_channels'].forEach((v) {
        mChannels!.add(new MChannels.fromJson(v));
      });
    }
    if (json['m_p_channels'] != null) {
      mPChannels = <MPChannels>[];
      json['m_p_channels'].forEach((v) {
        mPChannels!.add(new MPChannels.fromJson(v));
      });
    }
    if (json['t_direct_draft'] != null) {
      tDirectDraft = <TDirectDraft>[];
      json['t_direct_draft'].forEach((v) {
        tDirectDraft!.add(new TDirectDraft.fromJson(v));
      });
    }
    if (json['t_direct_thread_draft'] != null) {
      tDirectThreadDraft = <TDirectThreadDraft>[];
      json['t_direct_thread_draft'].forEach((v) {
        tDirectThreadDraft!.add(new TDirectThreadDraft.fromJson(v));
      });
    }
    if (json['t_group_draft'] != null) {
      tGroupDraft = <TGroupDraft>[];
      json['t_group_draft'].forEach((v) {
        tGroupDraft!.add(new TGroupDraft.fromJson(v));
      });
    }
    if (json['t_group_threads_draft'] != null) {
      tGroupThreadsDraft = <TGroupThreadsDraft>[];
      json['t_group_threads_draft'].forEach((v) {
        tGroupThreadsDraft!.add(new TGroupThreadsDraft.fromJson(v));
      });
    }
    directMsgcounts = json['direct_msgcounts'].cast<int>();
    allUnreadCount = json['all_unread_count'];
    mChannelsids = json['m_channelsids'].cast<int>();
    directDraftCounts = json['direct_draft_status_counts'].cast<int>();
    groupDraftCounts = json['group_draft_status_counts'].cast<int>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.mWorkspace != null) {
      data['m_workspace'] = this.mWorkspace!.toJson();
    }
    if (this.mUsers != null) {
      data['m_users'] = this.mUsers!.map((v) => v.toJson()).toList();
    }
    if (this.currentUser != null) {
      data['current_user'] = this.currentUser!.toJson();
    }
    if (this.mChannels != null) {
      data['m_channels'] = this.mChannels!.map((v) => v.toJson()).toList();
    }
    if (this.mPChannels != null) {
      data['m_p_channels'] = this.mPChannels!.map((v) => v.toJson()).toList();
    }
    if (this.tDirectDraft != null) {
      data['t_direct_draft'] =
          this.tDirectDraft!.map((v) => v.toJson()).toList();
    }
    if (this.tDirectThreadDraft != null) {
      data['t_direct_thread_draft'] =
          this.tDirectThreadDraft!.map((v) => v.toJson()).toList();
    }
    if (this.tGroupDraft != null) {
      data['t_group_draft'] = this.tGroupDraft!.map((v) => v.toJson()).toList();
    }
    if (this.tGroupThreadsDraft != null) {
      data['t_group_threads_draft'] =
          this.tGroupThreadsDraft!.map((v) => v.toJson()).toList();
    }
    data['direct_msgcounts'] = this.directMsgcounts;
    data['all_unread_count'] = this.allUnreadCount;
    data['m_channelsids'] = this.mChannelsids;
    data['direct_draft_status_counts'] = directDraftCounts;
    data['group_draft_status_counts'] = groupDraftCounts;

    return data;
  }
}

class MWorkspace {
  int? id;
  String? workspaceName;
  String? createdAt;
  String? updatedAt;

  MWorkspace({this.id, this.workspaceName, this.createdAt, this.updatedAt});

  MWorkspace.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    workspaceName = json['workspace_name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['workspace_name'] = this.workspaceName;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class MUsers {
  int? id;
  String? name;
  String? email;
  String? passwordDigest;
  String? profileImage;
  String? rememberDigest;
  bool? activeStatus;
  bool? admin;
  bool? memberStatus;
  String? createdAt;
  String? updatedAt;
  String? imageUrl;

  MUsers({
    this.id,
    this.name,
    this.email,
    this.passwordDigest,
    this.profileImage,
    this.rememberDigest,
    this.activeStatus,
    this.admin,
    this.memberStatus,
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
  });

  MUsers.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    passwordDigest = json['password_digest'];
    profileImage = json['image_url'];
    rememberDigest = json['remember_digest'];
    activeStatus = json['active_status'];
    admin = json['admin'];
    memberStatus = json['member_status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    imageUrl = json['image_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['email'] = this.email;
    data['password_digest'] = this.passwordDigest;
    data['image_url'] = this.profileImage;
    data['remember_digest'] = this.rememberDigest;
    data['active_status'] = this.activeStatus;
    data['admin'] = this.admin;
    data['member_status'] = this.memberStatus;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['image_url'] = this.imageUrl;
    return data;
  }
}

class CurrentUser {
  int? id;
  String? name;
  String? email;
  String? passwordDigest;
  String? profileImage;
  String? rememberDigest;
  bool? activeStatus;
  bool? admin;
  bool? memberStatus;
  String? imageUrl;
  String? createdAt;
  String? updatedAt;

  CurrentUser(
      {this.id,
      this.name,
      this.email,
      this.passwordDigest,
      this.profileImage,
      this.rememberDigest,
      this.activeStatus,
      this.admin,
      this.memberStatus,
      this.imageUrl,
      this.createdAt,
      this.updatedAt});

  CurrentUser.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    passwordDigest = json['password_digest'];
    profileImage = json['profile_image'];
    rememberDigest = json['remember_digest'];
    activeStatus = json['active_status'];
    admin = json['admin'];
    memberStatus = json['member_status'];
    memberStatus = json['member_status'];
    imageUrl = json['profile_image_url'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['email'] = this.email;
    data['password_digest'] = this.passwordDigest;
    data['profile_image'] = this.profileImage;
    data['remember_digest'] = this.rememberDigest;
    data['active_status'] = this.activeStatus;
    data['admin'] = this.admin;
    data['member_status'] = this.memberStatus;
    data['profile_image_url'] = this.imageUrl;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class MChannels {
  int? id;
  String? channelName;
  bool? channelStatus;
  int? messageCount;

  MChannels({this.id, this.channelName, this.channelStatus, this.messageCount});

  MChannels.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    channelName = json['channel_name'];
    channelStatus = json['channel_status'];
    messageCount = json['message_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['channel_name'] = this.channelName;
    data['channel_status'] = this.channelStatus;
    data['message_count'] = this.messageCount;
    return data;
  }
}

class MPChannels {
  int? id;
  String? channelName;
  bool? channelStatus;

  MPChannels({this.id, this.channelName, this.channelStatus});

  MPChannels.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    channelName = json['channel_name'];
    channelStatus = json['channel_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['channel_name'] = this.channelName;
    data['channel_status'] = this.channelStatus;
    return data;
  }
}

class TDirectDraft {
  String? name;
  String? receiverName;
  String? directmsg;
  int? id;
  String? createdAt;
  String? imageUrl;
  bool? draftMessageStatus;
  int? sendUserId;
  int? receiverUserId;
  bool? senderActiveStatus;
  bool? receiverActiveStatus;
  List<dynamic>? fileUrls;
  List<dynamic>? fileNames;

  TDirectDraft(
      {this.name,
      this.directmsg,
      this.id,
      this.createdAt,
      this.imageUrl,
      this.draftMessageStatus,
      this.sendUserId,
      this.fileUrls,
      this.fileNames,
      this.receiverActiveStatus,
      this.receiverName,
      this.receiverUserId,
      this.senderActiveStatus});

  TDirectDraft.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    directmsg = json['directmsg'];
    id = json['id'];
    createdAt = json['created_at'];
    imageUrl = json['image_url'];
    draftMessageStatus = json['draft_message_status'];
    fileUrls = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    receiverActiveStatus = json['active_status'];
    receiverName = json['receiver_name'];
    receiverUserId = json['receiver_id'];
    senderActiveStatus = json['sender_active_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['directmsg'] = this.directmsg;
    data['id'] = this.id;
    data['created_at'] = this.createdAt;
    data['image_url'] = this.imageUrl;
    data['draft_message_status'] = this.draftMessageStatus;
    data['send_user_id'] = this.sendUserId;
    data['file_urls'] = this.fileUrls;
    data['file_names'] = this.fileNames;
    data['active_status'] = this.receiverActiveStatus;
    data['receiver_name'] = this.receiverName;
    data['receiver_id'] = this.receiverUserId;
    data['sender_active_status'] = this.senderActiveStatus;
    return data;
  }
}

class TDirectThreadDraft {
  String? name;
  String? receiverName;
  String? directthreadmsg;
  int? id;
  int? directMessageId;
  int? receiverID;
  String? createdAt;
  String? imageUrl;
  bool? draftMessageStatus;
  List<dynamic>? fileUrls;
  List<dynamic>? fileNames;
  List<dynamic>? directFileUrls;
  List<dynamic>? directFileNames;
  bool? activeStatus;

  TDirectThreadDraft(
      {this.name,
      this.directthreadmsg,
      this.id,
      this.createdAt,
      this.imageUrl,
      this.draftMessageStatus,
      this.fileUrls,
      this.fileNames,
      this.receiverName,
      this.directFileNames,
      this.directFileUrls,
      this.activeStatus,
      this.directMessageId});

  TDirectThreadDraft.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    directthreadmsg = json['directthreadmsg'];
    id = json['id'];
    createdAt = json['created_at'];
    imageUrl = json['image_url'];
    draftMessageStatus = json['draft_message_status'];
    fileUrls = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    directFileNames = json['direct_file_names'] as List<dynamic>?;
    directFileUrls = json['direct_files_urls'] as List<dynamic>?;
    receiverName = json['receiver_name'];
    activeStatus = json['active_status'];
    receiverID = json['receiver_id'];
    directMessageId = json['direct_msg_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['directthreadmsg'] = this.directthreadmsg;
    data['id'] = this.id;
    data['created_at'] = this.createdAt;
    data['image_url'] = this.imageUrl;
    data['draft_message_status'] = this.draftMessageStatus;
    data['image_url'] = this.fileUrls;
    data['file_names'] = this.fileNames;
    data['direct_file_names'] = this.directFileNames;
    data['direct_files_urls'] = this.directFileUrls;
    data['receiver_name'] = this.receiverName;
    data['active_status'] = this.activeStatus;
    data['receiver_id'] = this.receiverID;
    data['direct_msg_id'] = this.directMessageId;
    return data;
  }
}

class TGroupDraft {
  String? name;
  String? groupmsg;
  int? id;
  String? createdAt;
  String? imageUrl;
  String? channelName;
  int? sendUserId;
  bool? draftMessageStatus;
  List<dynamic>? fileUrls;
  List<dynamic>? fileNames;

  TGroupDraft(
      {this.name,
      this.groupmsg,
      this.id,
      this.createdAt,
      this.imageUrl,
      this.channelName,
      this.sendUserId,
      this.draftMessageStatus,
      this.fileUrls,
      this.fileNames});

  TGroupDraft.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    groupmsg = json['groupmsg'];
    id = json['id'];
    createdAt = json['created_at'];
    imageUrl = json['image_url'];
    channelName = json['channel_name'];
    sendUserId = json['send_user_id'];
    draftMessageStatus = json['draft_message_status'];
    fileUrls = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['groupmsg'] = this.groupmsg;
    data['id'] = this.id;
    data['created_at'] = this.createdAt;
    data['image_url'] = this.imageUrl;
    data['channel_name'] = this.channelName;
    data['send_user_id'] = this.sendUserId;
    data['draft_message_status'] = this.draftMessageStatus;
    data['image_url'] = this.fileUrls;
    data['file_names'] = this.fileNames;
    return data;
  }
}

class TGroupThreadsDraft {
  String? name;
  String? groupthreadmsg;
  String? groupMessage;
  String? groupMessageCreateAt;
  int? channelId;
  int? id;
  String? createdAt;
  String? channelName;
  int? sendUserId;
  String? imageUrl;
  bool? draftMessageStatus;
  List<dynamic>? fileUrl;
  List<dynamic>? fileName;
  List<dynamic>? groupfileUrl;
  List<dynamic>? groupfileName;
  int? groupMessageId;

  TGroupThreadsDraft(
      {this.name,
      this.groupthreadmsg,
      this.id,
      this.createdAt,
      this.channelName,
      this.sendUserId,
      this.imageUrl,
      this.draftMessageStatus,
      this.fileUrl,
      this.fileName,
      this.channelId,
      this.groupMessage,
      this.groupMessageCreateAt,
      this.groupfileName,
      this.groupfileUrl,
      this.groupMessageId});

  TGroupThreadsDraft.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    groupthreadmsg = json['groupthreadmsg'];
    id = json['id'];
    createdAt = json['created_at'];
    channelName = json['channel_name'];
    sendUserId = json['send_user_id'];
    imageUrl = json['image_url'];
    draftMessageStatus = json['draft_message_status'];
    fileUrl = json['file_urls'] as List<dynamic>?;
    fileName = json['file_names'] as List<dynamic>?;
    channelId = json['channel_id'];
    groupMessage = json['groupmsg'];
    groupMessageId = json['group_msg_id'];
    groupMessageCreateAt = json['group_created_at'];
    groupfileName = json['group_file_name'] as List<dynamic>?;
    groupfileUrl = json['group_file_url'] as List<dynamic>?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['groupthreadmsg'] = this.groupthreadmsg;
    data['id'] = this.id;
    data['created_at'] = this.createdAt;
    data['channel_name'] = this.channelName;
    data['send_user_id'] = this.sendUserId;
    data['image_url'] = this.imageUrl;
    data['draft_message_status'] = this.draftMessageStatus;
    data['image_url'] = this.fileUrl;
    data['file_names'] = this.fileName;
    data['channel_id'] = this.channelId;
    data['groupmsg'] = this.groupMessage;
    data['group_created_at'] = this.groupMessageCreateAt;
    data['group_file_name'] = this.groupfileName;
    data['group_file_url'] = this.groupfileUrl;
    data['group_msg_id'] = this.groupMessageId;
    return data;
  }
}
