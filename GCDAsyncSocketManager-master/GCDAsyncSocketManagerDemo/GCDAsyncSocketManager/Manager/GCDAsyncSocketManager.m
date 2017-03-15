//
//  FIMSocketManager.m
//  FIMMobSDK
//
//  Created by 宫城 on 15/9/11.
//  Copyright (c) 2015年 宫城. All rights reserved.
/*
    AsyncSocket 管理者
 */

#import "GCDAsyncSocketManager.h"
#import "GCDAsyncSocket.h"

static const NSInteger TIMEOUT = 30;        // 超时时长
static const NSInteger kBeatLimit = 3;      // 击败限制

@interface GCDAsyncSocketManager ()

@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, assign) NSInteger beatCount;      // 发送心跳次数，用于重连
@property (nonatomic, strong) NSTimer *beatTimer;       // 心跳定时器
@property (nonatomic, strong) NSTimer *reconnectTimer;  // 重连定时器
@property (nonatomic, strong) NSString *host;           // Socket连接的host地址
@property (nonatomic, assign) uint16_t port;            // Sokcet连接的port

@end

@implementation GCDAsyncSocketManager


// 单利
+ (GCDAsyncSocketManager *)sharedInstance {
    static GCDAsyncSocketManager *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // 设置默认的连接状态
    self.connectStatus = -1;
    
    return self;
}

#pragma mark - socket actions
// 切换 端口 和 ip
- (void)changeHost:(NSString *)host port:(NSInteger)port {
    self.host = host;
    self.port = port;
}


// 连接 socket 并设置代理
- (void)connectSocketWithDelegate:(id)delegate {
    
    // socket 连接状态为非 -1 标识已经连接，不需要再进行连接
    if (self.connectStatus != -1) {
        NSLog(@"Socket Connect: YES");
        return;
    }
    
    // 设置连接状态为 0
    self.connectStatus = 0;
    
    
    // 创建 socket
    // 代理回调队列在主队列
    self.socket =
    [[GCDAsyncSocket alloc] initWithDelegate:delegate delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    
    // 开始连接
    if (![self.socket connectToHost:self.host
                             onPort:self.port
                        withTimeout:TIMEOUT
                              error:&error]) {
        
        // 连接失败
        self.connectStatus = -1;
        NSLog(@"connect error: --- %@", error);
    }
}


// GCDAsyncSocketDelegate

// 连接开始， 开始心跳
- (void)socketDidConnectBeginSendBeat:(NSString *)beatBody {
    
    self.connectStatus = 1;
    // 重新连接的次数
    self.reconnectionCount = 0;
    
    if (!self.beatTimer) {
        self.beatTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                          target:self
                                                        selector:@selector(sendBeat:)
                                                        userInfo:beatBody
                                                         repeats:YES];
        
        [[NSRunLoop mainRunLoop] addTimer:self.beatTimer forMode:NSRunLoopCommonModes];
    }
}


// 失去连接后，进行重新连接
- (void)socketDidDisconectBeginSendReconnect:(NSString *)reconnectBody {
    
    self.connectStatus = -1;
    
    if (self.reconnectionCount >= 0 && self.reconnectionCount <= kBeatLimit) {
        NSTimeInterval time = pow(2, self.reconnectionCount);
        if (!self.reconnectTimer) {
            self.reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:time
                                                                   target:self
                                                                 selector:@selector(reconnection:)
                                                                 userInfo:reconnectBody
                                                                  repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:self.reconnectTimer forMode:NSRunLoopCommonModes];
        }
        self.reconnectionCount++;
    } else {
        [self.reconnectTimer invalidate];
        self.reconnectTimer = nil;
        self.reconnectionCount = 0;
    }
}


// socket 发送数据
- (void)socketWriteData:(NSString *)data {
    NSData *requestData = [data dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:requestData withTimeout:-1 tag:0];
    [self socketBeginReadData];
}


// socket 接收数据
- (void)socketBeginReadData {
    [self.socket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:10 maxLength:0 tag:0];
}


// 断开连接
- (void)disconnectSocket {
    self.reconnectionCount = -1;
    [self.socket disconnect];
    
    [self.beatTimer invalidate];
    self.beatTimer = nil;
}

#pragma mark - public method
- (void)resetBeatCount {
    self.beatCount = 0;
}

#pragma mark - private method
- (void)sendBeat:(NSTimer *)timer {
    if (self.beatCount >= kBeatLimit) {
        [self disconnectSocket];
        return;
    } else {
        self.beatCount++;
    }
    if (timer != nil) {
        [self socketWriteData:timer.userInfo];
    }
}

- (void)reconnection:(NSTimer *)timer {
    NSError *error = nil;
    if (![self.socket connectToHost:self.host onPort:self.port withTimeout:TIMEOUT error:&error]) {
        self.connectStatus = -1;
    }
}

@end
