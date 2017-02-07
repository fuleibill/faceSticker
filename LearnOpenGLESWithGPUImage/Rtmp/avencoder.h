

#pragma once
#ifndef _avencoder_h_
#define _avencoder_h_

#define OBS_OUTPUT_SUCCESS         0
#define OBS_OUTPUT_BAD_PATH       -1
#define OBS_OUTPUT_CONNECT_FAILED -2
#define OBS_OUTPUT_INVALID_STREAM -3
#define OBS_OUTPUT_ERROR          -4
#define OBS_OUTPUT_DISCONNECTED   -5
#define OBS_OUTPUT_UNSUPPORTED    -6
#define OBS_OUTPUT_NO_SPACE       -7

#include "rtmp-stream.h"
#include "obs-avc.h"

#ifdef __cplusplus
extern "C" {
#endif
    
    struct video_encoder{
        int width;
        int height;
        int fps;
        int bps;
        unsigned char header[1024];  //sps andd pps
        int headersize;
        char name[128];
    };
    
    struct audio_encoder{
        int bps;
        int channels;
        int samplesize;
        int samplerate;
        unsigned char header[128];  //maybe 4 bytes
        int headersize;
        char name[128];
    };
    
    struct rtmp_service{
        int drop_threshold_ms; //ms
        int max_shutdown_time_sec;
        int audioAheadtime;//ms
        
        char server_url[1024];
        char server_key[256];
        char user_name[128];
        char user_password[128];
        int server_url_size;
        int server_key_size;
        int user_name_size;
        int user_password_size;
        
    };
    
    extern struct video_encoder* p_video_encoder;
    extern struct audio_encoder* p_audio_encoder;
    extern struct rtmp_service* p_rtmp_service;
    
    
    
    void setVideoParams(int width, int height, int fps, int bps,char* spspps, int spsppssize);
    void setAudioParams(int bps,int channels,int samplesize,int samplerate,char* aacheader,int aacheadersize);
    
    void setAudioSyncTime(/*int aheadms,*/int drop_threshold_ms,int max_shutdown_time_sec);
    void setRtmpParams(char* server_url,int server_urlsize,char* server_key,int server_keysize,
                       char* user_name,int user_namesize, char* user_password,int user_passwordsize);
    
    
    int create();
    void destroy();
    int isconnected();
    
    void push_video(uint64_t pts,uint8_t* data,int size,bool isKeyFrame);
    void push_audio(uint64_t pts,uint8_t* data,int size);
    bool start_send();
    void stop();
    void setVideoParams(int width, int height, int fps, int bps,char* spspps, int spsppssize);
    void setAudioParams(int bps,int channels,int samplesize,int samplerate,char* aacheader,int aacheadersize);
    void setAudioSyncTime(/*int aheadms,*/int drop_threshold_ms,int max_shutdown_time_sec);
    void setRtmpParams(char* server_url,int server_urlsize,char* server_key,int server_keysize,
                       char* user_name,int user_namesize, char* user_password,int user_passwordsize);
    uint64_t get_stream_total_bytes_sent();//yanyue add
    int get_stream_dropped_frames();//yanyue add

    
    /*
     
     void sendVideo(unsigned char* data, int size, int frameType,int64_t timestamp);
     void sendAudio(unsigned char* data, int size, int64_t timestamp);
     
     int64_t firstAudioTimestamp;
     int64_t firstVideoTimestamp;
     
     */
    //obs_data_set_default_int(defaults, OPT_DROP_THRESHOLD, 600);
    //obs_data_set_default_int(defaults, OPT_MAX_SHUTDOWN_TIME_SEC, 5);
    
#ifdef __cplusplus
}
#endif
#endif
