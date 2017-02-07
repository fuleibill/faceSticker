/******************************************************************************
    Copyright (C) 2013-2014 by Hugh Bailey <obs.jim@gmail.com>

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

#define MAX_AV_PLANES 8

/* time threshold in nanoseconds to ensure audio timing is as seamless as
 * possible */
#define TS_SMOOTHING_THRESHOLD 70000000ULL

/**
 * @file
 * @brief header for modules implementing encoders.
 *
 * Encoders are modules that implement some codec that can be used by libobs
 * to process output data.
 */

#ifdef __cplusplus
extern "C" {
#endif

/** Specifies the encoder type */
enum obs_encoder_type {
	OBS_ENCODER_AUDIO, /**< The encoder provides an audio codec */
	OBS_ENCODER_VIDEO  /**< The encoder provides a video codec */
};
    

/** Encoder output packet */
struct encoder_packet {
	uint8_t               *data;        /**< Packet data */
	size_t                size;         /**< Packet size */

	int64_t               pts;          /**< Presentation timestamp */
	int64_t               dts;          /**< Decode timestamp */

	int32_t               timebase_num; /**< Timebase numerator */
	int32_t               timebase_den; /**< Timebase denominator */

	enum obs_encoder_type type;         /**< Encoder type */

	bool                  keyframe;     /**< Is a keyframe */

	/* ---------------------------------------------------------------- */
	/* Internal video variables (will be parsed automatically) */

	/* DTS in microseconds */
	int64_t               dts_usec;

	/**
	 * Packet priority
	 *
	 * This is generally use by video encoders to specify the priority
	 * of the packet.
	 */
	int                   priority;

	/**
	 * Dropped packet priority
	 *
	 * If this packet needs to be dropped, the next packet must be of this
	 * priority or higher to continue transmission.
	 */
	int                   drop_priority;

	/** Audio track index (used with outputs) */
	size_t                track_idx;

	/** Encoder from which the track originated from */
    //ToDo
	void*         *encoder;
};
    

#ifdef __cplusplus
}
#endif
