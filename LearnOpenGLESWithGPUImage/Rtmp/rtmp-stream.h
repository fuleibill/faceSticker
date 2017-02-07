/******************************************************************************
    Copyright (C) 2014 by Hugh Bailey <obs.jim@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
******************************************************************************/

#pragma once

#include "util/c99defs.h"
#include "obs-encoder.h"
#ifdef __cplusplus
extern "C" {
#endif

    void *rtmp_stream_create();
    void rtmp_stream_data(void *data, struct encoder_packet *packet);
    void rtmp_stream_destroy(void *data);
    bool rtmp_stream_start(void *data);
    void rtmp_stream_stop(void *data);
    uint64_t rtmp_stream_total_bytes_sent(void *data);
    int rtmp_stream_dropped_frames(void *data);
    int rtmp_is_connected(void *data);
    uint64_t rtmp_drop_total_bytes();//yanyue add丢弃总字节数
    char *rtmp_get_ip_addr();//yanyue add获取连接服务器ip（push_ip字段）

#ifdef __cplusplus
}
#endif
