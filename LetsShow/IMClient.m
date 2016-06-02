//
//  IMClient.m
//  PipObjectC
//
//  Created by 吴建国 on 15/9/25.
//  Copyright © 2015年 wujianguo. All rights reserved.
//

#import "IMClient.h"
#include "MsgPacket.h"

@interface IMClient () <NSStreamDelegate>
@property (nonatomic) NSInputStream *inputStream;
@property (nonatomic) NSOutputStream *outputStream;
@property (nonatomic) unsigned char *buf;
@property (nonatomic) unsigned long buf_length;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) BOOL pingFlag;
@property (nonatomic) NSMutableArray *sendList;
@property (nonatomic) BOOL inputStreamOpened;
@property (nonatomic) BOOL outputStreamOpened;
@property (nonatomic) unsigned short seq;
@end

struct PackedMessage {
    unsigned char *buf;
    int len;
    int offset;
};

@implementation IMClient

- (instancetype)init {
    if (self = [super init]) {
        self.buf = (unsigned char*)malloc(MAX_MESSAGE_LENGTH);
        return self;
    }
    return self;
}

- (void)dealloc {
    if (self.buf) {
        free(self.buf);
    }
}

- (void)connectToHost:(NSString *)host withPort:(int)port {
    self.seq = 0;
    self.sendList = [[NSMutableArray alloc] init];
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStringRef cfHost = (__bridge CFStringRef)host;
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, cfHost, port, &readStream, &writeStream);
    self.inputStream = (__bridge_transfer NSInputStream *)readStream;
    self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    [self.outputStream open];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(handlePingTimer:) userInfo:nil repeats:YES];
    self.pingFlag = YES;
}

- (void)handlePingTimer:(NSTimer *)timer {
    if (self.pingFlag) {
        [self ping];
    } else {
        self.pingFlag = YES;
    }
}

- (void)close {
    [self.timer invalidate];
    self.inputStreamOpened = NO;
    self.outputStreamOpened = NO;
    [self.inputStream close];
    [self.outputStream close];
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream setDelegate:nil];
    [self.outputStream setDelegate:nil];
    
    while ([self.sendList count] > 0) {
        NSValue *v = (NSValue *)self.sendList[0];
        struct PackedMessage *m = v.pointerValue;
        free(m->buf);
        free(m);
        [self.sendList removeObjectAtIndex:0];
    }
}

- (void)sendToTarget:(unsigned long long)target withMsg:(NSString *)message {
    NSLog(@"%@", message);
    if (!self.inputStreamOpened || !self.outputStreamOpened) {
        if ([self.delegate respondsToSelector:@selector(onError)]) {
            [self.delegate onError];
        }
        return;
    }
    unsigned short msg_length = [message lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    unsigned char *msg = (unsigned char*)[message cStringUsingEncoding:NSUTF8StringEncoding];
    int buf_length = calculate_send_packet_length(msg_length);
    unsigned char *packet = (unsigned char*)malloc(msg_length + buf_length);
    pack_send_message(self.seq++, target, msg, msg_length, packet, buf_length);
    NSInteger sendsize = [self.outputStream write:packet maxLength:buf_length];
    if (sendsize < buf_length) {
        struct PackedMessage *packedMsg = (struct PackedMessage*)malloc(sizeof(struct PackedMessage));
        packedMsg->buf = packet;
        packedMsg->len = buf_length;
        packedMsg->offset = (int)sendsize;
        [self.sendList addObject:[NSValue valueWithPointer:packedMsg]];
    } else {
        free(packet);
    }
    self.pingFlag = NO;
}

- (void)ping {
    unsigned char packet[2] = {0};
    [self.outputStream write:packet maxLength:2];
}

- (void)onReadable {
//    int temp_buf_length = MAX_MESSAGE_LENGTH + 10;
//    unsigned char *temp_buf = malloc(temp_buf_length);
    NSInteger read_ret = [self.inputStream read:self.buf + self.buf_length maxLength:MAX_MESSAGE_LENGTH];//-self.buf_length];
    if (read_ret <= 0) {
        [self close];
        if ([self.delegate respondsToSelector:@selector(onError)]) {
            [self.delegate onError];
        }
        return;
    }
    //    printf("self.buf[0] :0x%X \n",self.buf[3]);
//    memcpy(self.buf + self.buf_length,temp_buf,read_ret);
//    free(temp_buf);
    if (read_ret <= 0) {
        [self close];
        if ([self.delegate respondsToSelector:@selector(onError)]) {
            [self.delegate onError];
        }
        return;
    }
    unsigned long read_length = read_ret;
    self.buf_length += read_length;
//    NSLog(@"buf length = %ld",self.buf_length);
    unsigned long buf_offset = 0;
    while (1) {
        unsigned long need_length = 0;
        int msg_type = detect_cur_message(self.buf + buf_offset, self.buf_length - buf_offset, &need_length);
//        printf("msg_type : %d",msg_type);
//        NSLog(@"detect_cur_message result:%d", msg_type);
        if (msg_type == MsgPacketTypeSendResp) {
            unsigned short seq = 0;
            unsigned char result = '\0';
            buf_offset += unpack_send_resp_message(self.buf + buf_offset, self.buf_length - buf_offset, &seq, &result);
            continue;
        } else if (msg_type == MsgPacketTypeReceiveMessage) {
            unsigned long long source = 0;
            unsigned char *msg = (unsigned char*)malloc(need_length);
//            printf("need_length is : %lu\n",need_length);
            unsigned short msg_length = 0;
            buf_offset += unpack_receive_message(self.buf + buf_offset, self.buf_length - buf_offset, &source, msg, &msg_length);
            NSString *msgStr = [[NSString alloc] initWithBytes:msg length:msg_length encoding:NSUTF8StringEncoding];
            free(msg);
            if (!msgStr) {
                @throw [NSException exceptionWithName:@"msgStr is nil" reason:@"But this is impossible!You must to check the code" userInfo:nil];
//                NSLog(@"msgStr is nil this is impossible!You must to check the code");
            }
//            NSLog(@"source:%llu,msgStr:%@", source, msgStr);
            [self.delegate onMessageFromSrc:source withMsg:msgStr];
            continue;
        }
        break;
    }
    
    //读取完整数据之后,还有剩余的,则copy回buf中
    if (buf_offset > 0) {
        self.buf_length -= buf_offset;
        memcpy(self.buf, self.buf + buf_offset, self.buf_length);
    }
    
}

- (void)onWritable {
    
    while ([self.sendList count] > 0) {
        NSValue *v = (NSValue *)self.sendList[0];
        struct PackedMessage *m = v.pointerValue;
        NSInteger sendsize =  [self.outputStream write:m->buf+m->offset maxLength:m->len-m->offset];
        self.pingFlag = NO;
        m->offset += sendsize;
        if (m->offset < m->len) {
            break;
        } else {
            free(m->buf);
            free(m);
            [self.sendList removeObjectAtIndex:0];
        }
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
//    NSLog(@"%@, %lu", aStream, (unsigned long)eventCode);
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
//            NSLog(@"readable");
            if (aStream == self.inputStream) {
                [self onReadable];
            }
            break;
        case NSStreamEventHasSpaceAvailable:
//            NSLog(@"writable");
            if (aStream == self.outputStream) {
                [self onWritable];
            }
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"NSStreamEventEndEncountered");
            [self close];
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"NSStreamEventErrorOccurred");
            [self close];
            if ([self.delegate respondsToSelector:@selector(onError)]) {
                [self.delegate onError];
            }
            break;
        case NSStreamEventOpenCompleted:
            if (self.inputStream == aStream) {
                self.inputStreamOpened = YES;
            } else if (self.outputStream == aStream) {
                self.outputStreamOpened = YES;
            }
            if (self.inputStreamOpened && self.outputStreamOpened) {
                if ([self.delegate respondsToSelector:@selector(onConnected)]) {
                    [self.delegate onConnected];
                }
            }
            break;
        default:
            NSLog(@"handleEvent %@, %lu", aStream, (unsigned long)eventCode);
            [self close];
            if ([self.delegate respondsToSelector:@selector(onError)]) {
                [self.delegate onError];
            }

            break;
    }
}


@end
