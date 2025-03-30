//
//  ChatMessageView.m
//  ChatInterface
//
//  Created by Muhammad Hassan on 2025-03-14.
//

#import "ChatMessageView.h"

@implementation ChatMessageView

- (instancetype)initWithMessage:(NSString *)message isUserMessage:(BOOL)isUser {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Initialize the message label
        self.messageLabel = [[UILabel alloc] init];
        self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.messageLabel.numberOfLines = 0;
        self.messageLabel.font = [UIFont systemFontOfSize:22];
        self.messageLabel.text = message;
        [self addSubview:self.messageLabel];
        
        if (isUser) {
            // User message: Add a bubble view
            self.messageBubbleView = [[UIView alloc] init];
            self.messageBubbleView.translatesAutoresizingMaskIntoConstraints = NO;
            self.messageBubbleView.layer.cornerRadius = 12; // Rounded corners for the bubble
            self.messageBubbleView.backgroundColor = [[UIColor systemGray4Color] colorWithAlphaComponent:0.6];
            self.messageLabel.textAlignment = NSTextAlignmentRight;
            [self.messageLabel setTextColor:[UIColor blackColor]];
            [self addSubview:self.messageBubbleView];
            
            // Add the message label inside the bubble
            [self.messageBubbleView addSubview:self.messageLabel];
            
            // Constraints for the bubble view and label
            [NSLayoutConstraint activateConstraints:@[
                // Bubble view constraints
                [self.messageBubbleView.topAnchor constraintEqualToAnchor:self.topAnchor],
                [self.messageBubbleView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                [self.messageBubbleView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10], // Align to the right
                [self.messageBubbleView.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor multiplier:0.9], // Maximum width (75% of screen width)
                
                // Message label constraints inside the bubble
                [self.messageLabel.topAnchor constraintEqualToAnchor:self.messageBubbleView.topAnchor constant:8],
                [self.messageLabel.bottomAnchor constraintEqualToAnchor:self.messageBubbleView.bottomAnchor constant:-8],
                [self.messageLabel.leadingAnchor constraintEqualToAnchor:self.messageBubbleView.leadingAnchor constant:12],
                [self.messageLabel.trailingAnchor constraintEqualToAnchor:self.messageBubbleView.trailingAnchor constant:-12]
            ]];
        } else {
            // Bot message: Plain text without a bubble
            [NSLayoutConstraint activateConstraints:@[
                // Message label constraints
                [self.messageLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
                [self.messageLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8],
                [self.messageLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10], // Align to the left
                [self.messageLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-10] // Ensure it doesn't overlap with user messages
            ]];
            
            // Set text color for bot messages
            self.messageBubbleView.backgroundColor = [UIColor clearColor];
            self.messageLabel.textAlignment = NSTextAlignmentLeft;
            [self.messageLabel setTextColor:[UIColor darkGrayColor]];
        }
    }
    return self;
}

- (void)updateMessageText:(NSString *)text {
    self.messageLabel.text = text;
    
    // Force layout update to ensure the bubble resizes to fit the text
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
