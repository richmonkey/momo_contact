#ifndef _DEFINEENUM_
#define _DEFINEENUM_

#define PARSE_NULL_STR(nsstr) nsstr ? nsstr : @""

#define CONSTRAINT_UPLOAD_IMAGE_SIZE 1024.0f
#define CONSTRAINT_UPLOAD_IMAGE_QUALITY 0.8f

#define HTTP_REQUEST_TIME_OUT_SECONDS 60	//download or upload timeout seconds

#define BIG_AVATAR_SIZE 780


//修改联系人信息时的数据
typedef enum{
    //
    kMoDefault,
    //电话
	kMoTel =0x01,				
    //邮箱
	kMoMail=0x02,				
    //网址 个人主页
	kMoUrl = 0x03,			
    //人员  关系	
	kMoPerson=0x04,			
    //地址
	kMoAdr = 0x05,			
    //纪念日
	kMoBday=0x06,	
	
    //即时通讯
	kMoInstantMessage = 0x10,
	kMoIm91U,			//91U
	kMoImQQ,				//QQ
	kMoImMSN,				//msn
	kMoImICQ,				//ICQ
	kMoImGtalk,				//Gtalk
	kMoImYahoo,				//yahoo
	kMoImSkype,				//skype
	kMoImAIM,				//aim
	kMoImJabber,			//jabber	
    
	//联系人分组
	kMoCategory = 0x20,			//联系人分组
    
    //contact
	kMoContactID = 0x40,		//ID
	kMoFirstName,			//名字
	kMoLastName,			//姓
	kMoOrganization,		//公司   //学校
	kMoDepartment,			//部门
	kMoNote,				//备注  //简介
	kMoBirthday,			//生日
	kMoJobTitle,			//职称
	kMoNickName,			//昵称
	kMoMiddleName,			//中间名称
    
	
	//注册名
	kMoRegisterName = 0x50,
	//居住地
	kMoResidence,
	//性别
	kMoGender,
	//生肖
	kMoAnimalSign,
	//星座
	kMoZodiac,	
	
	//头像
	kMoimage = 0x80			//头像图片
}_contactType;

#define kMoCommonType kMoDefault
typedef int ContactType;

typedef enum {
    // 邮箱 地址 电话 IM
    kMoLabelHomeType = 0x0000 // 住宅
    , kMoLabelWorkType          // 工作
    , kMoLabelOtherType         // 其他
    
    // 电话
    , kMoTelLabelCellType = 0x0010 // 手机
    , kMoTelLabelHomeFaxType // 住宅传真
    , kMoTelLabelWorkFaxType // 工作传真
    , kMoTelLabelPagerType // 传呼机
    , kMoTelLabelCarType   // 车载电话
    , kMoTelLabelIPhoneType // IPHone手机
    , kMoTelLabelMainTyp    // 主要
    
    // URL
    , kMoUrlLabelHomepageType = 0x0020  // 个人主页
    , kMoUrlLabelFtpType   // FTP
    , kMoUrlLabelBlogType   // 个人博客
    , kMoUrlProfileType     // 个人页面
    
    // 日期
    , kMoDateLabelAnniversaryType = 0x0030 // 纪念日
    
    // 相关人
    , kMoRelatedNameLabelSpouseType = 0x0040 // 配偶
    , kMoRelatedNameLabelChildType  // 小孩
    , kMoRelatedNameLabelFatherType // 父亲
    , kMoRelatedNameLabelMotherType // 母亲
    , kMoRelatedNameLabelParentType // 父母亲
    , kMoRelatedNameLabelBrotherType // 兄弟
    , kMoRelatedNameLabelSisterType // 姐妹
    , kMoRelatedNameLabelFriendType // 朋友
    , kMoRelatedNameLabelRelativeType // 亲戚
    , kMoRelatedNameLabelDomestic_partnerType // 国内合作伙伴
    , kMoRelatedNameLabelManagerType // 领导
    , kMoRelatedNameLabelAssistantType // 助理
    , kMoRelatedNameLabelPartnerType // 合伙人
    , kMoRelatedNameLabelReferred_byType // 
}_labelType;
typedef int LabelType;


// 动态草稿
enum _draftType {
	draftMessage,
	draftComment,
	draftRetweet,
};
typedef int DraftType;



enum _uploadStatus {
	uploadNone,
	uploadWait,
	uploadUploading,
	uploadSuccess,
	uploadFailed,
};
typedef int UploadStatus;

typedef enum     
{
	MQ_OPERATION_OK,				//正常
	MQ_OPEN_SOCKET_ERROR,		//打开socket出错
	MQ_OPEN_CONNECTION_ERROR,	//连接出错
	MQ_OPEN_CHANNEL_ERROR,		//打开通道出错
	MQ_OPERATION_ERROR,			//
	MQ_DECLARE_EXCHANGE_ERROR,	//EXCHANGE申明出错
	MQ_DECLARE_QUEUE_ERROR,		//队列申明出错
	MQ_BIND_QUEUE_ERROR,			//队列绑定
	MQ_PUBLISH_MSG_ERROR,		//发送消息出错
	MQ_NULL_CONNECTION,			//无法连接
	MQ_CONSUMER_ERROR,			//消费者，收信息出错
	MQ_UNEXCEPTRCV,				//
	
	MQ_CONTINUE_RECEVIE_MSG,				//
	MQ_EXIT_RECEVIE_MSG,				//
	
	MQ_COMMON_ERROR,
	
} MMMQErrorType;

typedef enum {
	MMMessageTypeNone = 0,			//未知
	MMMessageTypeSignature = 1,		//签名
	MMMessageTypeGroup = 2,			//群组
	MMMessageTypePhoto = 3,			//照片
	MessageTypeText = 4,			//文本广播
	MMMessageTypeBlog = 5,			//日志
	MMMessageTypeVote = 6,			//投票
	MMMessageTypeActivity = 7,		//活动
	MMMessageTypeSecondHand = 8,	//二手信息
}MMMessageType;

typedef enum {
	MMAccessoryTypeNone = 0,		//未知
	MMAccessoryTypeImage = 1,		//图片
	MMAccessoryTypeFile = 2,		//文件
} MMAccessoryType;

#define kMMMQIMNewChatMsg			@"MQIMNewChatMsg"
#define kMMMQIMChatRespone			@"MQIMChatRespone"
#define kMMMQSysMsg					@"MQSysMsg	"
#define kMMMQFeedMsg				@"MQFeedMsg"
#define kMMMQMayKnownMsg            @"MQMayKnownMsg"
#define kMMMQOauthExpired           @"MMMQOauthExpired" //oauth失效, 需要重新登陆

#define kMMMQSendMsgResult			@"MQSendMsgResult"
#define kMMMQContactChangedMsg      @"MQContactChangedMsg"
#define kMMMQContactGroupChangedMsg @"MQContactGroupChangedMsg"
#define kMMMQAboutMeMsg             @"MQAboutMeMsg"
#define kMMNewAboutMeMsg            @"MMNewAboutMeMsg"

#define kMMAppDidBecomeInactive     @"MMAppDidBecomeInactive"
#define kMMAppDidBecomeActive       @"MMAppDidBecomeActive"

#define kMMSysMsgTypeAddFriendRequest 1
#define kMMSysMsgTypeBecomeFriend 2
#define kMMSysMsgTypeAcceptAddFriendRequest 3
#define kMMSysMsgTypeIntroduceFriend 4
#define kMMSysMsgTypeJoinGroupRequest 5
#define kMMSysMsgTypeAcceptJoinGroupRequest 6
#define kMMSysMsgTypeInviteJoinGroupRequest 7
#define kMMSysMsgTypeFriendInfoChange 8
#define kMMSysMsgTypeInviteJoinParty 9
#define kMMSysMsgTypePartyInfoChange 10


#define kMMMessageDeleted		@"MessageDeleted"
#define kMMAllMessageDeleted	@"AllMessageDeleted"

#define kMMGroupListChanged     @"MMGroupListChanged"

typedef enum {
	MMAppTypeUnknow = -1,
	MMAppTypeGroup = 7,
	MMAppTypeActivity = 15,
} MMAppType;


//关于我的king类型："1表示评论，2表示留言，3表示评论中提到我，4表示赞，5广播中提到，6表示回复"
typedef enum {
	MMAboutMeMessageKindComment = 1,
	MMAboutMeMessageKindLeaveMessage = 2,
	MMAboutMeMessageKindAtComment = 3,
	MMAboutMeMessageKindPraise = 4,
	MMAboutMeMessageKindBroadcast = 5,
	MMAboutMeMessageKindReply = 6	
} MMAboutMeMessageKind;


typedef enum {
    SMCP_UNKNOWW = 0,
    
    //连接管理消息
    SMCP_SYS_HEARTBEAT = 0x0001,						//心跳： 0x0001(1)
    //包体为空
    SMCP_SYS_HEARTBEAT_MODI_REQUEST = 0x0011,		//修改心跳时间：0x0011(17)上行
    SMCP_SYS_HEARTBEAT_MODI = 0x0012,				//修改心跳事件响应：0x0012(18)下行
    
    SMCP_SYS_LOGIN_TOKEN = 0x0101,					//token登录请求：0x0101(257)(不可用)
    SMCP_SYS_LOGIN_TOKEN_RESPONSE = 0x0102,			//token登录响应：0x0102(258)
    
    
    SMCP_SYS_LOGIN_ACCPWD = 0x0111,					//用户名密码登录： 0x0111(273)（不可用）
    SMCP_SYS_LOGIN_ACCPWD_RESPONSE = 0x0112,			//登录响应：0x0112(274)(不可用)
    
    SMCP_SYS_LOGOUT = 0x0f01,							//登出通知：0x0f01(3841)上行
    
    //c2s:	
    //c2s-通讯簿相关请求？
    //c2s-http代理请求消息
    SMCP_HTTP_PROXY_REQUEST = 0x1f01,				//http代理请求：0x1f01(7937)
    SMCP_HTTP_PROXY_RESPONSE = 0x1f02,				//http代理请求响应：0x1f02(7938)
    
    
    //s2c:
    //s2c-通讯簿相关消息？
    //s2c-mq转发消息：系统消息
    SMCP_SM_NOTICE = 0x2f01,					//下发系统消息：0x2f01(12033)
    
    //c2c-mq转发消息:普通文本消息
    SMCP_IM_1V1 = 0x3001,								//普通单对单：0x3001(12289)
    SMCP_IM_1V1_RESPONSE = 0x3002,					//普通单对单响应：0x3002(12290)
    
    SMCP_IM_1V1_NO_UID = 0x3011,						//普通单对单:无uid, 0x3011(12305)
    SMCP_IM_1V1_NO_UID_RESPONSE = 0x3012,				//普通单对单:无uid响应, 0x3012(12306)
    
    SMCP_IM_1VN = 0x3101,								//普通单对多：0x3101(12545)
    SMCP_IM_1VN_RESPONSE = 0x3102,					//普通单对多响应：0x3102(12546)
    
    SMCP_IM_DELIVER = 0x3f01,					//下发普通mq消费消息： 0x3f01(16129)
    SMCP_IM_DELIVER_RESPONSE = 0x3f02,				//下发普通mq消费消息响应：0x3f02(16130)
    
    //c2c-mq转发消息：语音消息
    SMCP_AUDIO_1V1 = 0x4001,							//语音单对单: 0x4001(16385)
    SMCP_AUDIO_1V1_FIN_ACK = 0x4013,                    //单对单边录边传接收完毕
    
    SMCP_AUDIO_DELIVER = 0x4f01,						//下发语音mq消费消息：0x4f01(20225)
    
    //c2c群组消息
    
    
} MM_SMCP_CMD_TYPE;


#define numberLeastLength 8
#define mobileNotRegister -1
#define mobileInvalid -2


typedef enum {
    kMMShowBigPhoto,
    kMMShowSmallPhoto,
    kMMShowNoPhoto,
} MM_SHOW_PHOTO_TYPE;

typedef enum {
	MMSelectGroupTypeAllFriend,		//全部好友
	MMSelectGroupTypeAllMessage,	//全部动态
	MMSelectGroupTypeRecentActivity,	//最近活动
	MMSelectGroupTypeGroup,
	MMSelectGroupTypeActivity,
	MMSelectGroupFavorite,			//收藏动态列表
} MMSelectGroupType;

typedef enum{
    kMMGroupMemberGradeNormal, //普通成员
    kMMGroupMemberGradeManager, //管理员
    kMMGroupMemberGradeOwner,  //群主
} MMGroupMemberGrade;


#endif

