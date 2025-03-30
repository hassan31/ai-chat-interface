//
//  ChatViewController.m
//  ChatInterface
//
//  Created by Muhammad Hassan on 2025-03-12.
//

#import "ChatViewController.h"
#import "ChatMessageView.h"
#import <objc/runtime.h>

@interface ChatViewController () <UITextViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *messageStackView; // To hold the chat messages
@property (nonatomic, strong) UIView *inputContainerView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UITextView *inputTextView;
@property (nonatomic, strong) NSLayoutConstraint *inputTextViewHeightConstraint; // Height constraint for dynamic resizing
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) NSArray<NSString *> *botMessages;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *messages;

@property (nonatomic, assign) NSInteger charIndex;
@property (nonatomic, assign) BOOL isUserScrolling; // Track if the user is manually scrolling
@property (nonatomic, strong) UIView *topCustomView;
@property (nonatomic, strong) UIButton *topButton;
@property (nonatomic, assign) CGFloat topViewHeight;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSInteger framesPerCharacter; // Number of frames to wait before showing the next character
@property (nonatomic, assign) NSInteger frameCounter;       // Counter to track frames
@property (nonatomic, strong) NSLayoutConstraint *inputContainerBottomConstraint;

@end

@implementation ChatViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    [self setupConstraints];
    [self registerKeyboardNotifications];
    [self addTapGestureToDismissKeyboard];
    
    // Send initial welcome message from the bot
    [self sendInitialBotMessage];
}

#pragma mark - Setup

- (void)setupView {
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initializeMessages];
    [self setupTopCustomView];
    [self setupScrollView];
    [self setupMessageStackView];
    [self setupInputContainer];
    [self setupTextView];
    [self setupPlaceholder];
    [self setupSendButton];
    [self setupStopButton];
}

- (void)initializeMessages {
    // Initialize bot messages array
    self.messages = [NSMutableArray array];
    self.botMessages = @[
        @"Hello! How can I help you today?",
        @"Hello! I'm here to assist you with any questions or concerns you may have. Feel free to ask me anything!",
        @"Hi there! What can I do for you?",
        @"Hi there! Let me know how I can help you today. I'm here to provide support and answer your questions.",
        @"Hey! Let me know if you need any assistance.",
        @"Greetings! I'm your virtual assistant. How can I assist you today? Don't hesitate to ask me anything!",
        @"Greetings! How may I assist you?",
        @"Hello! I'm your virtual assistant, ready to help you with anything you need. What's on your mind today?",
        @"Hi! Feel free to ask me anything.",
        @"Hi there! I'm here to assist you with any questions or tasks. Let me know how I can help you today!",
    ];
}

- (void)setupTopCustomView {
    // Setup Top Custom View
    self.topViewHeight = 90;
    self.topCustomView = [[UIView alloc] init];
    self.topCustomView.translatesAutoresizingMaskIntoConstraints = NO;
    self.topCustomView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.topCustomView];
    
    // Setup Button inside Top Custom View
    self.topButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.topButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.topButton setTitle:@"Action Button" forState:UIControlStateNormal];
    [self.topButton.titleLabel setFont:[UIFont systemFontOfSize:22]];
    [self.topButton addTarget:self action:@selector(userDidSelectOnButton) forControlEvents:UIControlEventTouchUpInside];
    [self.topCustomView addSubview:self.topButton];
}

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.delegate = self;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];
}

- (void)setupMessageStackView {
    self.messageStackView = [[UIStackView alloc] init];
    self.messageStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageStackView.axis = UILayoutConstraintAxisVertical;
    self.messageStackView.spacing = 10;
    [self.scrollView addSubview:self.messageStackView];
}

- (void)setupInputContainer {
    self.inputContainerView = [[UIView alloc] init];
    self.inputContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputContainerView.backgroundColor = [UIColor systemGray6Color];
    [self.view addSubview:self.inputContainerView];
}

- (void)setupTextView {
    self.inputTextView = [[UITextView alloc] init];
    self.inputTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputTextView.delegate = self;
    self.inputTextView.font = [UIFont systemFontOfSize:22];
    self.inputTextView.backgroundColor = [UIColor whiteColor];
    self.inputTextView.layer.cornerRadius = 5;
    self.inputTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.inputTextView.layer.borderWidth = 1.0;
    self.inputTextView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    self.inputTextView.scrollEnabled = NO;
    [self.inputContainerView addSubview:self.inputTextView];

    // Add height constraint for dynamic resizing
    self.inputTextViewHeightConstraint = [self.inputTextView.heightAnchor constraintEqualToConstant:36];
    self.inputTextViewHeightConstraint.active = YES;
}

- (void)setupPlaceholder {
    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.text = @"Type a message...";
    self.placeholderLabel.font = [UIFont systemFontOfSize:22];
    self.placeholderLabel.textColor = [UIColor lightGrayColor];
    self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inputTextView addSubview:self.placeholderLabel];

    // Add constraints for the placeholder label
    [NSLayoutConstraint activateConstraints:@[
        [self.placeholderLabel.leadingAnchor constraintEqualToAnchor:self.inputTextView.leadingAnchor constant:8],
        [self.placeholderLabel.topAnchor constraintEqualToAnchor:self.inputTextView.topAnchor constant:8],
    ]];
    
    // Hide the placeholder when the text view has text
    self.placeholderLabel.hidden = self.inputTextView.text.length > 0;
}

- (void)setupSendButton {
    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.sendButton.backgroundColor = [UIColor clearColor];
    
    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sendButton setImage:[UIImage imageNamed:@"send_btn"] forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.sendButton setEnabled:NO];
    [self.sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [self.inputContainerView addSubview:self.sendButton];
}

- (void)setupStopButton {
    self.stopButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.stopButton.backgroundColor = [UIColor clearColor];
    self.stopButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.stopButton setImage:[UIImage imageNamed:@"stop_btn"] forState:UIControlStateNormal];
    self.stopButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.stopButton addTarget:self action:@selector(stopBotTyping) forControlEvents:UIControlEventTouchUpInside];
    [self.inputContainerView addSubview:self.stopButton];
    self.stopButton.hidden = YES; // Initially hidden
}

- (void)setupConstraints {
    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    
    self.inputContainerBottomConstraint = [self.inputContainerView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor];
    
    [NSLayoutConstraint activateConstraints:@[
        // Top Custom View constraints
        [self.topCustomView.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
        [self.topCustomView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.topCustomView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.topCustomView.heightAnchor constraintEqualToConstant:self.topViewHeight],
        
        // Button constraints inside Top Custom View
        [self.topButton.centerXAnchor constraintEqualToAnchor:self.topCustomView.centerXAnchor],
        [self.topButton.centerYAnchor constraintEqualToAnchor:self.topCustomView.centerYAnchor],
        
        // ScrollView constraints
        [self.scrollView.topAnchor constraintEqualToAnchor:self.topCustomView.bottomAnchor],
        [self.scrollView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.scrollView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.inputContainerView.topAnchor],
        
        // Message StackView constraints
        [self.messageStackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor constant:10],
        [self.messageStackView.leftAnchor constraintEqualToAnchor:self.scrollView.leftAnchor constant:10],
        [self.messageStackView.rightAnchor constraintEqualToAnchor:self.scrollView.rightAnchor constant:-10],
        [self.messageStackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor constant:-10],
        [self.messageStackView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor constant:-20]
    ]];
    
    // Input Container constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.inputContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.inputContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        self.inputContainerBottomConstraint,
        [self.inputContainerView.heightAnchor constraintGreaterThanOrEqualToConstant:60],
    ]];

    // Input TextView constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.inputTextView.leadingAnchor constraintEqualToAnchor:self.inputContainerView.leadingAnchor constant:10],
        [self.inputTextView.trailingAnchor constraintEqualToAnchor:self.sendButton.leadingAnchor constant:-10],
        [self.inputTextView.topAnchor constraintEqualToAnchor:self.inputContainerView.topAnchor constant:8],
        [self.inputTextView.bottomAnchor constraintEqualToAnchor:self.inputContainerView.bottomAnchor constant:-8],
    ]];

    // Send Button constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.sendButton.trailingAnchor constraintEqualToAnchor:self.inputContainerView.trailingAnchor constant:-10],
        [self.sendButton.centerYAnchor constraintEqualToAnchor:self.inputContainerView.centerYAnchor],
        [self.sendButton.widthAnchor constraintEqualToConstant:28],
        [self.sendButton.heightAnchor constraintEqualToConstant:28],
    ]];

    // Stop Button constraints (same as Send Button)
    [NSLayoutConstraint activateConstraints:@[
        [self.stopButton.trailingAnchor constraintEqualToAnchor:self.inputContainerView.trailingAnchor constant:-10],
        [self.stopButton.centerYAnchor constraintEqualToAnchor:self.inputContainerView.centerYAnchor],
        [self.stopButton.widthAnchor constraintEqualToConstant:28],
        [self.stopButton.heightAnchor constraintEqualToConstant:28],
    ]];
}

- (void)registerKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)addTapGestureToDismissKeyboard {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)sendInitialBotMessage {
    // Show the Stop button and hide the Send button
    [self showStopButton];
    
    NSString *welcomeMessage = @"Hello! How can I assist you today?";
    [self sendBotReplyWithMessage:welcomeMessage];
}

- (void)showStopButton {
    self.sendButton.hidden = YES;
    self.stopButton.hidden = NO;
}

- (void)showSendButton {
    self.sendButton.hidden = NO;
    self.stopButton.hidden = YES;
}

#pragma mark - Actions

- (void)userDidSelectOnButton {
    // Handle button tap
}

- (void)sendMessage {
    NSString *text = self.inputTextView.text;
    if (text.length == 0) {
        return;
    }
    
    [self.view endEditing:YES];
    
    // Add message to messages array
    [self.messages addObject:@{@"text": text, @"isUser": @YES}];
    
    // Create a new message view and add it to the stack view
    ChatMessageView *messageView = [[ChatMessageView alloc] initWithMessage:text isUserMessage:YES];
    [self.messageStackView addArrangedSubview:messageView];
    
    // Clear input field
    self.inputTextView.text = @"";
    [self.sendButton setEnabled:NO];
    
    // Reset the text view height to its original value
    self.inputTextViewHeightConstraint.constant = 36; // Reset to initial height
    self.inputTextView.scrollEnabled = NO; // Disable scrolling
    
    // Update placeholder visibility
    [self updatePlaceholderVisibility];
    
    // Add some extra space at the bottom of scrollview when message is sent
    UIEdgeInsets contentInset = self.scrollView.contentInset;
    contentInset.bottom = 150;
    self.scrollView.contentInset = contentInset;
    
    // Show the Stop button and hide the Send button
    [self showStopButton];
    
    // Scroll to the latest message after inserting the new message
    [self scrollToLatestMessageIfNeeded];
    
    // Simulate bot reply after delay
    [self performSelector:@selector(sendBotReply) withObject:nil afterDelay:1.0];
}

- (void)sendBotReply {
    NSString *botFullMessage = self.botMessages[arc4random_uniform((uint32_t)self.botMessages.count)];
    [self sendBotReplyWithMessage:botFullMessage];
}

- (void)sendBotReplyWithMessage:(NSString *)message {
    // Add a placeholder message to the data source
    NSMutableDictionary *botMessageDict = [@{@"text": @"", @"isUser": @NO} mutableCopy];
    [self.messages addObject:botMessageDict];
    
    // Create a new message view and add it to the stack view
    ChatMessageView *messageView = [[ChatMessageView alloc] initWithMessage:@"" isUserMessage:NO];
    [self.messageStackView addArrangedSubview:messageView];
    
    // Force layout update to ensure the scrollView's content size is correct
    [self.scrollView layoutIfNeeded];
    
    // Scroll to the bot's message as soon as it starts typing
    [self scrollToLatestMessageIfNeeded];
    
    // Start the typing animation
    [self startTypingAnimationForMessage:message messageView:messageView botMessageDict:botMessageDict];
}

- (void)startTypingAnimationForMessage:(NSString *)message messageView:(ChatMessageView *)messageView botMessageDict:(NSMutableDictionary *)botMessageDict {
    // Initialize animation speed
    self.framesPerCharacter = 10; // Adjust this value to control the speed
    self.frameCounter = 0;

    // Start a CADisplayLink for the typing animation
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateTypingAnimation:)];
    if (@available(iOS 10.0, *)) {
        self.displayLink.preferredFramesPerSecond = 10; // Reduce frame rate to 30 FPS
    }
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

    // Store the message and messageView for the animation
    objc_setAssociatedObject(self.displayLink, "message", message, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.displayLink, "messageView", messageView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.displayLink, "botMessageDict", botMessageDict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)updateTypingAnimation:(CADisplayLink *)displayLink {
    self.frameCounter++;

    // Only update every 2 frames (reduce frequency)
    if (self.frameCounter % 2 != 0) {
        return;
    }

    NSString *message = objc_getAssociatedObject(displayLink, "message");
    ChatMessageView *messageView = objc_getAssociatedObject(displayLink, "messageView");
    NSMutableDictionary *botMessageDict = objc_getAssociatedObject(displayLink, "botMessageDict");

    if (self.charIndex < message.length) {
        // Append the next character to the typing message
        NSString *typingMessage = [message substringToIndex:self.charIndex + 1];
        [messageView updateMessageText:typingMessage];

        // Update the message in the data source
        botMessageDict[@"text"] = typingMessage;

        // Avoid unnecessary layout updates
        [messageView setNeedsDisplay]; // Use this instead of layoutIfNeeded

        // Scroll to the latest message only if the user is not manually scrolling
        if (!self.isUserScrolling) {
            [self scrollToLatestMessageIfNeeded];
        }

        self.charIndex++;
    } else {
        // Stop the displayLink when the message is fully displayed
        [displayLink invalidate];
        self.displayLink = nil;

        // Reset charIndex for the next message
        self.frameCounter = 0;
        self.charIndex = 0;

        // Show the Send button and hide the Stop button
        [self showSendButton];

        // Re-enable the send button
        self.sendButton.enabled = self.inputTextView.text.length > 0;

        if (self.isUserScrolling == NO) {
            // Scroll to the latest message after the bot's typing animation is complete
            [self scrollToLatestMessageIfNeeded];
        } else {
            self.isUserScrolling = NO;
        }
    }
}

- (void)stopBotTyping {
    // Invalidate the displayLink to stop the typing animation
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    
    // Clear the associated objects
    objc_removeAssociatedObjects(self.displayLink);
    self.frameCounter = 0;
    self.charIndex = 0;
    
    // Show the Send button and hide the Stop button
    [self showSendButton];
    
    self.isUserScrolling = NO;
    
    // Re-enable the send button
    self.sendButton.enabled = self.inputTextView.text.length > 0;
}

- (void)scrollToLatestMessageIfNeeded {
    // Force layout update to ensure the scrollView's content size is correct
    [self.scrollView layoutIfNeeded];
    
    // Calculate the bottom offset
    CGFloat bottomOffset = self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.scrollView.contentInset.bottom;
    
    // Scroll to the bottom if the latest message is not visible
    if (bottomOffset > self.scrollView.contentOffset.y) {
        [self.scrollView setContentOffset:CGPointMake(0, bottomOffset) animated:YES];
    }
}

#pragma mark - Keyboard Handling

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16;

    // Adjust the bottom constraint of inputContainerView
    self.inputContainerBottomConstraint.constant = -keyboardFrame.size.height + 35;

    // Animate with the same curve and duration as the keyboard
    [UIView animateWithDuration:duration delay:0 options:curve animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        // Scroll to the bottom only if the latest message is not already visible
        if (![self isLatestMessageVisible]) {
            [self.scrollView layoutIfNeeded];
            CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.scrollView.contentInset.bottom);
            [self.scrollView setContentOffset:bottomOffset animated:YES];
        }
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    double duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    // Reset the bottom constraint of inputContainerView
    self.inputContainerBottomConstraint.constant = 0;

    // Animate the layout change
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (BOOL)isLatestMessageVisible {
    // Get the last message view in the stack view
    UIView *lastMessageView = self.messageStackView.arrangedSubviews.lastObject;
    if (!lastMessageView) {
        return YES; // No messages, so technically the latest message is "visible"
    }
    
    // Convert the last message view's frame to the scrollView's coordinate system
    CGRect lastMessageFrame = [self.scrollView convertRect:lastMessageView.bounds fromView:lastMessageView];
    
    // Check if the last message is within the scrollView's visible bounds
    return CGRectContainsRect(self.scrollView.bounds, lastMessageFrame);
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    // Calculate the required height for the text view
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, CGFLOAT_MAX)];
    CGFloat newHeight = newSize.height;

    // Define the maximum height (5 lines of text)
    CGFloat maxHeight = textView.font.lineHeight * 8 + textView.textContainerInset.top + textView.textContainerInset.bottom;

    // Cap the height at the maximum height
    if (newHeight > maxHeight) {
        newHeight = maxHeight;
        textView.scrollEnabled = YES; // Enable scrolling when max height is reached
    } else {
        textView.scrollEnabled = NO; // Disable scrolling when height is less than max
    }

    // Update the height constraint of the input container view
    self.inputContainerView.frame = CGRectMake(self.inputContainerView.frame.origin.x,
                                               self.inputContainerView.frame.origin.y,
                                               self.inputContainerView.frame.size.width,
                                               newHeight + 16); // Add padding (8 top + 8 bottom)

    // Update the height constraint of the text view
    self.inputTextViewHeightConstraint.constant = newHeight;

    // Animate the layout change
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    }];

    // Enable/disable the send button based on whether the text view is empty
    self.sendButton.enabled = textView.text.length > 0;

    // Update placeholder visibility
    [self updatePlaceholderVisibility];
}

- (void)updatePlaceholderVisibility {
    self.placeholderLabel.hidden = self.inputTextView.text.length > 0;
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // User started manually scrolling
    self.isUserScrolling = YES;
}

@end
