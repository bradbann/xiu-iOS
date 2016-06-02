//
//  MsgPacket.c
//  PipObjectC
//
//  Created by 吴建国 on 15/9/25.
//  Copyright © 2015年 wujianguo. All rights reserved.
//

#include "MsgPacket.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>

int calculate_send_packet_length(unsigned short msg_length) {
    return msg_length + MSG_HEADER_LENGTH + 1 + 2 + 8;
}

int pack_ping_message(unsigned char *packet_buf, int buf_length) {
    if (buf_length < MSG_HEADER_LENGTH) {
        return 0;
    }
    packet_buf[0] = '\0';
    packet_buf[1] = '\0';
    return MSG_HEADER_LENGTH;
}

int pack_send_message(unsigned short seq, unsigned long long target, unsigned char* msg, unsigned short msg_length, unsigned char *packet_buf, int buf_length) {
    int len_except_msg = 13;
    if (buf_length < len_except_msg + msg_length) {
        return 0;
    }
    unsigned short body_length = htons(msg_length + len_except_msg - MSG_HEADER_LENGTH);
    unsigned short nseq = htons(seq);
    unsigned long long ntarget = htonll(target);
    
    memcpy(packet_buf, &body_length, 2);
    packet_buf[2] = MsgPacketTypeSendMessage;
    memcpy(packet_buf + 3, &nseq, 2);
    memcpy(packet_buf + 5, &ntarget, 8);
    memcpy(packet_buf + len_except_msg, msg, msg_length);
    return len_except_msg + msg_length;
}

int detect_cur_message(unsigned char *buf, unsigned long buf_length, unsigned long *need_len) {
    if (buf_length < MSG_HEADER_LENGTH) {
        *need_len = MSG_HEADER_LENGTH;
        return MsgPacketErrorNotEnough;
    }
    unsigned short body_length = 0;
    memcpy(&body_length, buf, 2);
    body_length = ntohs(body_length);//size
    *need_len = body_length + MSG_HEADER_LENGTH;
    if (body_length == 0) {
        return MsgPacketTypePing;
    }
    if (body_length > buf_length - MSG_HEADER_LENGTH) {
        return MsgPacketErrorNotEnough;
    }
    unsigned char msg_type = buf[MSG_HEADER_LENGTH];//buf[2]
    return msg_type;
}

int unpack_send_resp_message(unsigned char *buf, unsigned long buf_length, unsigned short *seq, unsigned char *result) {
    if (buf_length < MSG_HEADER_LENGTH) {
        return 0;
    }
    unsigned short body_length = 0;
    memcpy(&body_length, buf, 2);
    body_length = ntohs(body_length);
    if (body_length > buf_length - MSG_HEADER_LENGTH) {
        return 0;
    }
    unsigned char msg_type = buf[MSG_HEADER_LENGTH];
    if (msg_type != MsgPacketTypeSendResp) {
        return 0;
    }
    memcpy(seq, buf + MSG_HEADER_LENGTH + 1, 2);
    *seq = ntohs(*seq);
    *result = buf[MSG_HEADER_LENGTH + 3];
    return MSG_HEADER_LENGTH + 4;
}

int unpack_receive_message(unsigned char *buf, unsigned long buf_length, unsigned long long *source, unsigned char *msg, unsigned short *msg_length) {
    if (buf_length < MSG_HEADER_LENGTH) {
        return 0;
    }
    unsigned short body_length = 0;
    memcpy(&body_length, buf, 2);
    body_length = ntohs(body_length);
    if (body_length > buf_length - MSG_HEADER_LENGTH) {
        return 0;
    }
    unsigned char msg_type = buf[MSG_HEADER_LENGTH];
    if (msg_type != MsgPacketTypeReceiveMessage) {
        return 0;
    }
    memcpy(source, buf + MSG_HEADER_LENGTH + 1, 8);
    *source = ntohll(*source);
    *msg_length = body_length - 1 - 8;
    memcpy(msg, buf + MSG_HEADER_LENGTH + 1 + 8, *msg_length);
    return MSG_HEADER_LENGTH + 9 + *msg_length;
}
