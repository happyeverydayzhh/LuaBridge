//
//  Macro_iOS.h
//  LuaBridge
//
//  Created by xie.pingjia
//  Copyright (c) 2015 Baidu. All rights reserved.
//

#ifndef CIKit_Macro_iOS_h
#define CIKit_Macro_iOS_h

#define CI_EXPORT

#ifndef IOS_VERSION_6_OR_ABOVE
#define IOS_VERSION_6_OR_ABOVE (([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0)? (YES):(NO))
#endif

#undef	CI_OC_AS_SINGLETON
#define CI_OC_AS_SINGLETON(__class) \
    - (__class *)sharedInstance; \
    + (__class *)sharedInstance;

#undef	CI_OC_DEF_SINGLETON
#define CI_OC_DEF_SINGLETON(__class) \
    - (__class *)sharedInstance \
    { \
        return [__class sharedInstance]; \
    } \
    + (__class *)sharedInstance \
    { \
        static dispatch_once_t once; \
        static __class * __singleton__; \
        dispatch_once( &once, ^{ __singleton__ = [[[self class] alloc] init]; } ); \
        return __singleton__; \
    }

#undef DEF_VIEW_RESPONDER
#define DEF_VIEW_RESPONDER(__NewClassName__, __OldClassName__) \
@interface __NewClassName__ : __OldClassName__ \
@property (nonatomic, weak) CIView *responder; \
@end \
@implementation __NewClassName__ \
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event \
{ \
    if (self.responder) { \
        if ([self.responder respondsToSelector:@selector(touchesBegan:withEvent:)]) { \
            [self.responder touchesBegan:touches withEvent:event]; \
        } \
    } \
} \
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event \
{ \
    if (self.responder) { \
        if ([self.responder respondsToSelector:@selector(touchesMoved:withEvent:)]) { \
            [self.responder touchesMoved:touches withEvent:event]; \
        } \
    } \
} \
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event \
{ \
    if (self.responder) { \
        if ([self.responder respondsToSelector:@selector(touchesEnded:withEvent:)]) { \
            [self.responder touchesEnded:touches withEvent:event]; \
        } \
    } \
} \
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event \
{ \
    if (self.responder) { \
        if ([self.responder respondsToSelector:@selector(touchesCancelled:withEvent:)]) { \
            [self.responder touchesCancelled:touches withEvent:event]; \
        } \
    } \
} \
@end

#define CI_OC_RELEASE(__object__) \
    do { \
        if (__object__) \
        { \
            [__object__ release]; \
            __object__ = nil; \
        } \
    } while(0);

#define CI_EQUALSTRING(__first__, __second__) \
    [__first__ isEqualToString:__second__]

#define CI_LAMBDA(__function__) std::function<void()> __function__ = [=]

#define CI_POST_TASK(__function__) \
    CIThread *__coreThread__ = [CIRunLoop sharedInstance].luaThread; \
    __coreThread__->postTask(BIND(__function__));

#define CI_POST_TASK_WITH_THREAD(__function__, __thread__) \
    __thread__->postTask(BIND(__function__));

#endif
