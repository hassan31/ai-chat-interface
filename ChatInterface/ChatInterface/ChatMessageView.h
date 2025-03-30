//
//  ChatMessageView.h
//  ChatInterface
//
//  Created by Muhammad Hassan on 2025-03-14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatMessageView : UIView

@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIView *messageBubbleView;

- (instancetype)initWithMessage:(NSString *)message isUserMessage:(BOOL)isUser;
- (void)updateMessageText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
