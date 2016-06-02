//
//  MsgPacket.h
//  PipObjectC
//
//  Created by 吴建国 on 15/9/25.
//  Copyright © 2015年 wujianguo. All rights reserved.
//

#ifndef MsgPacket_h
#define MsgPacket_h

#define MsgPacketTypeError 0
#define MsgPacketErrorNotEnough 255
#define MsgPacketTypePing 1
#define MsgPacketTypeSendMessage 32
#define MsgPacketTypeSendResp 33
#define MsgPacketTypeReceiveMessage 34

#define MAX_MESSAGE_LENGTH 65600

#define MSG_HEADER_LENGTH 2

int calculate_send_packet_length(unsigned short msg_length);

int pack_ping_message(unsigned char *packet_buf, int buf_length);
int pack_send_message(unsigned short seq, unsigned long long target, unsigned char* msg, unsigned short msg_length, unsigned char *packet_buf, int buf_length);

int detect_cur_message(unsigned char *buf, unsigned long buf_length, unsigned long *need_len);

int unpack_send_resp_message(unsigned char *buf, unsigned long buf_length, unsigned short *seq, unsigned char *result);
int unpack_receive_message(unsigned char *buf, unsigned long buf_length, unsigned long long *source, unsigned char *msg, unsigned short *msg_length);


#endif /* MsgPacket_h */
