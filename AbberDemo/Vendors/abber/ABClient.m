//
//  ABClient.m
//  AbberDemo
//
//  Created by Kevin on 8/6/14.
//  Copyright (c) 2014 Tapmob. All rights reserved.
//

#import "ABClient.h"
#import "internal/logger.h"

int handle_reply(xmpp_conn_t * const conn,
                 xmpp_stanza_t * const stanza,
                 void * const userdata)
{
  xmpp_stanza_t *query, *item;
  char *type, *name;
  
  type = xmpp_stanza_get_type(stanza);
  if (strcmp(type, "error") == 0)
    fprintf(stderr, "ERROR: query failed\n");
  else {
    query = xmpp_stanza_get_child_by_name(stanza, "query");
    printf("Roster:\n");
    for (item = xmpp_stanza_get_children(query); item;
         item = xmpp_stanza_get_next(item))
	    if ((name = xmpp_stanza_get_attribute(item, "name")))
        printf("\t %s (%s) sub=%s\n",
               name,
               xmpp_stanza_get_attribute(item, "jid"),
               xmpp_stanza_get_attribute(item, "subscription"));
	    else
        printf("\t %s sub=%s\n",
               xmpp_stanza_get_attribute(item, "jid"),
               xmpp_stanza_get_attribute(item, "subscription"));
    printf("END OF LIST\n");
  }
  
  /* disconnect */
  //xmpp_disconnect(conn);
  
  return 0;
}

void conn_handler(xmpp_conn_t * const conn, const xmpp_conn_event_t status,
                  const int error, xmpp_stream_error_t * const stream_error,
                  void * const userdata)
{
  xmpp_ctx_t *ctx = (xmpp_ctx_t *)userdata;
  xmpp_stanza_t *iq, *query;
  
  if (status == XMPP_CONN_CONNECT) {
    fprintf(stderr, "DEBUG: connected\n");
    
    /* create iq stanza for request */
    iq = xmpp_stanza_new(ctx);
    xmpp_stanza_set_name(iq, "iq");
    xmpp_stanza_set_type(iq, "get");
    xmpp_stanza_set_id(iq, "roster1");
    
    query = xmpp_stanza_new(ctx);
    xmpp_stanza_set_name(query, "query");
    xmpp_stanza_set_ns(query, XMPP_NS_ROSTER);
    
    xmpp_stanza_add_child(iq, query);
    
    /* we can release the stanza since it belongs to iq now */
    xmpp_stanza_release(query);
    
    /* set up reply handler */
    xmpp_id_handler_add(conn, handle_reply, "roster1", ctx);
    
    /* send out the stanza */
    xmpp_send(conn, iq);
    
    /* release the stanza */
    xmpp_stanza_release(iq);
  } else {
    fprintf(stderr, "DEBUG: disconnected\n");
    xmpp_stop(ctx);
  }
}

@implementation ABClient

#pragma mark - Memory management

- (id)init
{
  self = [super init];
  if (self) {
    
    xmpp_initialize();
    
    _ctx = xmpp_ctx_new(NULL, &ab_default_logger);
    
    _conn = xmpp_conn_new(_ctx);
    
  }
  return self;
}

- (void)dealloc
{
  xmpp_conn_release(_conn);
  
  xmpp_ctx_free(_ctx);
  
  xmpp_shutdown();
}


#pragma mark -

static ABClient *Client = nil;

+ (void)saveObject:(ABClient *)object
{
  Client = object;
}

+ (ABClient *)sharedObject
{
  return Client;
}



- (BOOL)connectWithPassport:(NSString *)pspt password:(NSString *)pswd
{
  if ( [pspt length]<=0 ) {
    return NO;
  }
  
  if ( [pswd length]<=0 ) {
    return NO;
  }
  
  const char *svr = NULL;
  if ( [_server length]>0 ) {
    svr = [_server UTF8String];
  }
  
  unsigned short prt = 0;
  prt = [_port intValue];
  
  
  xmpp_conn_set_jid(_conn, [pspt UTF8String]);
  
  xmpp_conn_set_pass(_conn, [pswd UTF8String]);
  
  if ( xmpp_connect_client(_conn, svr, prt, conn_handler, _ctx)!=0 ) {
    return NO;
  }
  
  [self performSelector:@selector(startRunning)
               onThread:[[self class] workingThread]
             withObject:nil
          waitUntilDone:NO];
  
  return YES;
}

- (NSString *)passport
{
  const char *pspt = xmpp_conn_get_jid(_conn);
  if ( pspt ) {
    return [[NSString alloc] initWithUTF8String:pspt];
  }
  return nil;
}

- (NSString *)password
{
  const char *pswd = xmpp_conn_get_pass(_conn);
  if ( pswd ) {
    return [[NSString alloc] initWithUTF8String:pswd];
  }
  return nil;
}

- (void)launch1
{
  NSLog(@"HERE1");
  [self performSelector:@selector(doit1)
               onThread:[[self class] workingThread]
             withObject:nil
          waitUntilDone:NO];
}

- (void)launch2
{
  NSLog(@"HERE2");
  [self performSelector:@selector(doit2)
               onThread:[[self class] workingThread]
             withObject:nil
          waitUntilDone:NO];
}

- (void)doit1
{
  while (1) {
    NSLog(@"doit1");
    [NSThread sleepForTimeInterval:0.5];
  }
}

- (void)doit2
{
  while (1) {
    NSLog(@"doit2");
    [NSThread sleepForTimeInterval:0.5];
  }
}



#pragma mark - Private methods

- (void)startRunning
{
  xmpp_run(_ctx);
}



#pragma mark - Working thread

+ (NSThread *)workingThread
{
  static NSThread *WorkingThread = nil;
  static dispatch_once_t Token;
  dispatch_once(&Token, ^{
    WorkingThread = [[NSThread alloc] initWithTarget:self
                                            selector:@selector(threadBody:)
                                              object:nil];
    [WorkingThread start];
  });
  return WorkingThread;
}

+ (void)threadBody:(id)object
{
  while ( YES ) {
    @autoreleasepool {
      [[NSRunLoop currentRunLoop] run];
    }
  }
}

@end
