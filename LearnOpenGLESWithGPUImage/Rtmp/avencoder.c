
#include "avencoder.h"
#include "rtmp-stream.h"
#include "obs-avc.h"
#include "librtmp/log.h"

//#include "test-log.h"

#include "util/dstr.h" //ian add

//obs_data_set_default_int(defaults, OPT_DROP_THRESHOLD, 600);
//obs_data_set_default_int(defaults, OPT_MAX_SHUTDOWN_TIME_SEC, 5);

//ian add for log
#define do_log(level, format, ...) \
blog(level, "[rtmp stream: '%s'] " format, \
"rtmp-stream", ##__VA_ARGS__)

#define warn(format, ...)  do_log(LOG_WARNING, format, ##__VA_ARGS__)
#define info(format, ...)  do_log(LOG_INFO,    format, ##__VA_ARGS__)
#define debug(format, ...) do_log(LOG_DEBUG,   format, ##__VA_ARGS__)
//////// end

 struct video_encoder* p_video_encoder;
 struct audio_encoder* p_audio_encoder;
 struct rtmp_service* p_rtmp_service;

static struct video_encoder ve = {0};
static struct audio_encoder ae = {0};
static struct rtmp_service  rs = {0};
static void*  p_rtmp_stream = NULL;


//todo thread protect
static bool created = false;

int create(){
    if(created)
        return 1;
    
    p_video_encoder = NULL;
    p_audio_encoder = NULL;
    p_rtmp_service = NULL;
    p_rtmp_stream = rtmp_stream_create();
    if(p_rtmp_stream == NULL)
        return 0;
    
    created = true;
    return 1;
}

void destroy(){
    if(created && p_rtmp_stream){
        rtmp_stream_destroy(p_rtmp_stream);
        created = false;
        p_rtmp_stream = NULL;
    }
}

int isconnected() {
	int result = 0;
    if(created && p_rtmp_stream){
    	result = rtmp_is_connected(p_rtmp_stream);
    }

	return result;
}

void push_video(uint64_t pts,uint8_t* data,int size,bool isKeyFrame){
    if(!created)
        return;
    
    struct encoder_packet ep = {0};
    ep.data = data;
    ep.dts_usec = pts;
    ep.size = size;
    ep.drop_priority = isKeyFrame?OBS_NAL_PRIORITY_HIGHEST:OBS_NAL_PRIORITY_LOW;
    ep.keyframe = isKeyFrame;
    ep.timebase_den = 1;
    ep.timebase_num = 1;
    ep.type = OBS_ENCODER_VIDEO;
    ep.track_idx = 0;
    ep.pts = pts / 1000;
    ep.dts = ep.pts;
    ep.priority = ep.drop_priority;
    rtmp_stream_data(p_rtmp_stream,&ep);
}

void push_audio(uint64_t pts,uint8_t* data,int size){
    if(!created)
        return;
    struct encoder_packet ep = {0};
    ep.data = data;
    ep.dts_usec = pts;
    ep.size = size;
    ep.drop_priority = OBS_NAL_PRIORITY_HIGHEST;
    ep.keyframe = true;
    ep.timebase_den = 1;
    ep.timebase_num = 1;
    ep.type = OBS_ENCODER_AUDIO;
    ep.track_idx = 0;
    ep.pts = pts / 1000;
    ep.dts = ep.pts;
    ep.priority = ep.drop_priority;
    rtmp_stream_data(p_rtmp_stream,&ep);
}

bool start_send(){
    if(!created)
        return false;

    return rtmp_stream_start(p_rtmp_stream);
}

void stop() {
    if(!created)
        return;

    return rtmp_stream_stop(p_rtmp_stream);
}

//yanyue add
uint64_t get_stream_total_bytes_sent()
{
    if (!created)
    {
        return 0;
    }
    return rtmp_stream_total_bytes_sent(p_rtmp_stream);
}

//yanyue add
int get_stream_dropped_frames()
{
    if (!created)
    {
        return 0;
    }
    return rtmp_stream_dropped_frames(p_rtmp_stream);
}

void setVideoParams(int width, int height, int fps, int bps,char* spspps, int spsppssize){
    memset(&ve, 0, sizeof(struct video_encoder));
    ve.bps = bps;
    ve.fps = fps;
    memcpy(ve.header,spspps,spsppssize);
    ve.height = height;
    ve.width = width;
    ve.headersize = spsppssize;
    ve.height = height;
    char* p = ve.name;
    strcpy(p,"android H264 mediacodec");
    p_video_encoder = &ve;
    
    //strcpy(ve.name,"android video mediacodec",strlen("android video mediacodec"));
};

void setAudioParams(int bps,int channels,int samplesize,int samplerate,char* aacheader,int aacheadersize){
    memset(&ae, 0, sizeof(struct audio_encoder));
    ae.bps = bps;
    ae.channels = channels;
    ae.samplesize = samplesize;
    ae.samplerate = samplerate;
//    ae.header[0] = 0xaf;
//    ae.header[1] = 0x0;
    
//    memcpy(ae.header+2,aacheader,aacheadersize);
//    ae.headersize = aacheadersize+2;
    memcpy(ae.header,aacheader,aacheadersize);
    ae.headersize = aacheadersize;
    char* p = ae.name;
    strcpy(p,"android aac mediacodec");
    p_audio_encoder = &ae;
};

void setAudioSyncTime(/*int aheadms,*/int drop_threshold_ms,int max_shutdown_time_sec){
    rs.audioAheadtime = 0;
    rs.drop_threshold_ms = drop_threshold_ms;
    rs.max_shutdown_time_sec = max_shutdown_time_sec;
    p_rtmp_service = &rs;
    
};

void setRtmpParams(char* server_url,int server_urlsize,char* server_key,int server_keysize,
                   char* user_name,int user_namesize, char* user_password,int user_passwordsize){
    memset(rs.server_url, 0, 1024);
    memcpy(rs.server_url, server_url, server_urlsize);
    rs.server_url_size = server_urlsize;
    memset(rs.server_key, 0, 256);
    memcpy(rs.server_key, server_key, server_keysize);
    rs.server_key_size = server_keysize;
    memset(rs.user_name, 0,128);
    memcpy(rs.user_name, user_name, user_namesize);
    rs.user_name_size = user_namesize;
    memset(rs.user_password, 0, 128);
    memcpy(rs.user_password, user_password, user_passwordsize);
    rs.user_password_size = user_passwordsize;
    rs.drop_threshold_ms = 2000; //600
    rs.max_shutdown_time_sec = 5;
    p_rtmp_service = &rs;
};

#ifdef rtmp_android
#ifdef __cplusplus
extern "C" {
#endif
#include <jni.h>
    
    jint Java_com_wukong_wukongtv_pushlive_WKTVScreenRecorder_rtmpCreate(JNIEnv *env, jobject jobj) {
        
        return create();
    }
    
    jint Java_com_wukong_wukongtv_pushlive_WKTVScreenRecorder_rtmpWriteH264Packet1(JNIEnv *env, jobject jobj, jlong pts, jint size, jint offset, jint flag, jobject byteBuf){

        void *dst = (*env)->GetDirectBufferAddress(env,byteBuf);
        push_video(pts,dst+offset,size,flag==1);

        return 1;
    }

    jint Java_com_wukong_wukongtv_pushlive_WKTVScreenRecorder_rtmpWriteAACPacket1(JNIEnv *env,jobject jobj, jlong pts, jint size, jobject byteBuf) {

        void *dst = (*env)->GetDirectBufferAddress(env,byteBuf);
        push_audio(pts,dst,size);
        
        return 1;
    }
    
    jint Java_com_wukong_wukongtv_pushlive_WKTVScreenRecorder_rtmpSetVideoParams(JNIEnv *env, jobject jobj, jint width, jint height, jint fps, jint bps, jobject spspps, jint spsppssize) {
        
        void *dst = (*env)->GetDirectBufferAddress(env,spspps);

//        const char *str = (*env)->GetStringUTFChars(env, strSpspps, 0);
//        char spspps[] = {0, 0, 0, 1, 103, 66, -128, 31, -38, 2, 32, 121, -17, -128, 109, 10, 19, 80, 0, 0, 0, 1, 104, -50, 6, -30};
        
//        char spspps[] = {0, 0, 0, 1, 103, 66, 0, 41, -115, -115, 64, 34, 1, -29, -53, -64, 60, 34, 17, 78, 0, 0, 0, 1, 104, -54, 67, -56};
        
        setVideoParams(width, height, fps, bps, dst, spsppssize);

        return 1;
    }
    
    jint Java_com_wukong_wukongtv_pushlive_WKTVScreenRecorder_rtmpSetAudioParams(JNIEnv *env, jobject jobj, jint bps, jint channels, jint samplesize, jint samplerate, jobject aacheader, jint aacheadersize) {

//        char byteAACHeader[] = {18, 16};
//        setAudioParams(64, 2, 16, 44, byteAACHeader, 2);

        void *aacheader_dst = (*env)->GetDirectBufferAddress(env, aacheader);
        setAudioParams(bps, channels, samplesize, samplerate, aacheader_dst, aacheadersize);

        return 1;
    }
    
    jint Java_com_wukong_wukongtv_pushlive_WKTVScreenRecorder_rtmpSetParams(JNIEnv *env, jobject jobj, jstring server_url, jint server_urlsize, jstring server_key, jint server_keysize, jstring user_name, jint user_namesize, jstring user_password, jint user_passwordsize) {

//        const char *strServer_url = "rtmp://101.200.160.218/hls";
//        const char *strServer_key = "abcd";
        
//        const char *strServer_url = "rtmp://cdn.live.360.cn/live_shouyou_push";
//        const char *strServer_key = "sn0004";
        
        const char *strServer_url = (*env)->GetStringUTFChars(env, server_url, 0);
        const char *strServer_key = (*env)->GetStringUTFChars(env, server_key, 0);
        const char *strUser_name = (*env)->GetStringUTFChars(env, user_name, 0);
        const char *strUser_password = (*env)->GetStringUTFChars(env, user_password, 0);
        
        setRtmpParams((char *)strServer_url, strlen(strServer_url), (char *)strServer_key, strlen(strServer_key), (char *)strUser_name, strlen(strUser_name), (char *)strUser_password, strlen(strUser_password));

        (*env)->ReleaseStringUTFChars(env, server_url, strServer_url);
        (*env)->ReleaseStringUTFChars(env, server_key, strServer_key);
        (*env)->ReleaseStringUTFChars(env, user_name, strUser_name);
        (*env)->ReleaseStringUTFChars(env, user_password, strUser_password);
        
        //LOGW("ian, do rtmpSetParams, url:%s, key:%s ", strServer_url, strServer_key);
        //RTMP_Log(RTMP_LOGINFO, "ian, %s: url: %s, key:%s \n", __FUNCTION__, strServer_url, strServer_key);
        //info("ian, %s: url: %s, key:%s \n", __FUNCTION__, strServer_url, strServer_key);

        return 1;
    }
    
    jint Java_com_wukong_wukongtv_pushlive_WKTVScreenRecorder_rtmpStart(JNIEnv *env, jobject jobj) {
        bool result = start_send();

        if (result) {
            return 1;
        } else {
            return 0;
        }
    }
    
    jint Java_com_wukong_wukongtv_pushlive_WKTVScreenRecorder_rtmpStop(JNIEnv *env, jobject jobj) {

        stop();

        return 1;
    }

    jint Java_com_wukong_wukongtv_pushlive_WKTVScreenRecorder_rtmpDestroy(JNIEnv *env, jobject jobj) {
        //LOGW("ian, do rtmpDestroy start  ");
        destroy();
        //LOGW("ian, do rtmpDestroy over ");
        return 1;
    }
    
    jint Java_com_wukong_wukongtv_pushlive_WKTVScreenRecorder_rtmpIsconnected(JNIEnv *env, jobject jobj) {
    	return isconnected();
    }

#ifdef __cplusplus
}
#endif
#endif
















