//
//  YCPlayerView.m
//  YCPlayerManager
//
//  Created by Durand on 24/2/17.
//  Copyright © 2017年 ych.wang@outlook.com. All rights reserved.
//

#import "YCPlayerView.h"
#import "YCMediaPlayer.h"

@interface YCPlayerView ()
{
    BOOL _isProgerssSliderActivity;
}

@end

@implementation YCPlayerView
@synthesize mediaPlayer = _mediaPlayer;
@synthesize playerStatus = _playerStatus;
@synthesize eventControl = _eventControl;
@synthesize currentTime = _currentTime;
@synthesize duration = _duration;

@synthesize playerControlBtn = _playerControlBtn;
@synthesize playerLayer = _playerLayer;
@synthesize loadingView = _loadingView;
@synthesize closeBtn = _closeBtn;
@synthesize bottomView = _bottomView;
@synthesize topView = _topView;
@synthesize titleLabel = _titleLabel;
@synthesize progressSlider = _progressSlider;
@synthesize loadingProgress = _loadingProgress;
@synthesize leftTimeLabel = _leftTimeLabel;
@synthesize rightTimeLabel = _rightTimeLabel;

@synthesize dateFormatter = _dateFormatter;


- (instancetype)initWithMediaPlayer:(YCMediaPlayer *)mediaPlayer
{
    self = [super init];
    if (self) {
        self.mediaPlayer = mediaPlayer;
        [self _setUpUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setUpUI];
        [self setUpLayoutWithFrame:frame];
    }
    return self;
}

- (void)setMediaPlayer:(YCMediaPlayer *)mediaPlayer
{
    _mediaPlayer = mediaPlayer;
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:mediaPlayer.player];
    self.playerLayer.frame = self.layer.bounds;
    self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    //视频的默认填充模式，AVLayerVideoGravityResizeAspect
//    self.playerLayer.videoGravity = AVLayerVideoGravityResize;
    [self.layer insertSublayer:_playerLayer atIndex:0];
}

- (void)setPlayerStatus:(YCMediaPlayerStatus)playerStatus
{
    _playerStatus = playerStatus;
    switch (playerStatus) {
        case YCMediaPlayerStatusFailed:
            [self.loadingView stopAnimating];
            [self setPlayerControlStatusPaused:YES];
            break;
        case YCMediaPlayerStatusBuffering:
            [self.loadingView startAnimating];
            [self setPlayerControlStatusPaused:YES];
            break;
        case YCMediaPlayerStatusReadyToPlay:
            [self.loadingView stopAnimating];
            self.duration = self.mediaPlayer.duration;
            [self setPlayerControlStatusPaused:NO];
            break;
        case YCMediaPlayerStatusPlaying:
            [self.loadingView stopAnimating];
            [self setPlayerControlStatusPaused:NO];
            break;
        case YCMediaPlayerStatusStopped:
            [self.loadingView stopAnimating];
            [self setPlayerControlStatusPaused:YES];
            break;
        case YCMediaPlayerStatusFinished:
            [self.loadingView stopAnimating];
            [self setPlayerControlStatusPaused:YES];
            break;
        default:
            break;
    }
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    _currentTime = currentTime;
    self.leftTimeLabel.text = [self changeToStringByTime:currentTime];
    if (!_isProgerssSliderActivity) {
        self.progressSlider.value = currentTime / self.duration;
    }
}

- (void)setDuration:(NSTimeInterval)duration
{
    if (!duration) {
        return;
    }
    _duration = duration;
    self.rightTimeLabel.text = [self changeToStringByTime:duration];
}

- (void)_setUpUI
{
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self addSubview:self.loadingView];
    
    //添加顶部视图
    self.topView = [[UIView alloc]init];
    self.topView.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.4];
    [self addSubview:self.topView];
    
    self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeBtn addTarget:self action:@selector(colseTheVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.closeBtn setImage:[self imageWithImageName:@"player_close"] forState:UIControlStateNormal];
    [self.topView addSubview:self.closeBtn];
    
    //标题
    self.titleLabel = [self labelWithTextAlignment:NSTextAlignmentCenter textColor:[UIColor whiteColor] fontSize:17];
    self.titleLabel.text = @"testTitle";
    [self.topView addSubview:self.titleLabel];
    
    //添加底部视图
    self.bottomView = [[UIView alloc]init];
    self.bottomView.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.4];
    [self addSubview:self.bottomView];
    
    //添加暂停和开启按钮
    self.playerControlBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playerControlBtn.showsTouchWhenHighlighted = YES;
    [self.playerControlBtn setImage:[self imageWithImageName:@"player_pause_nor"] forState:UIControlStateNormal];
    [self.playerControlBtn setImage:[self imageWithImageName:@"player_play_nor"] forState:UIControlStateSelected];
    [self.playerControlBtn addTarget:self action:@selector(didClickPlayerControlButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.bottomView addSubview:self.playerControlBtn];
    
    self.progressSlider = [[UISlider alloc]init];
    self.progressSlider.minimumValue = 0.0;
    [self.progressSlider setThumbImage:[self imageWithImageName:@"player_slider_pos"] forState:UIControlStateNormal];
    self.progressSlider.maximumTrackTintColor = [UIColor clearColor];
    self.progressSlider.value = 0.0;//指定初始值

    [self.progressSlider addTarget:self action:@selector(didStartDragProgressSlider:)  forControlEvents:UIControlEventValueChanged];
    [self.progressSlider addTarget:self action:@selector(didClickProgressSlider:) forControlEvents:UIControlEventTouchUpInside];

    UITapGestureRecognizer *progerssSliderTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapProgerssSlider:)];
    [self.progressSlider addGestureRecognizer:progerssSliderTap];
    
    self.progressSlider.backgroundColor = [UIColor clearColor];
    [self.bottomView addSubview:self.progressSlider];
    
    //loadingProgress
    self.loadingProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.loadingProgress.progressTintColor = [UIColor lightGrayColor];
    self.loadingProgress.trackTintColor    = [UIColor clearColor];
    [self.loadingProgress setProgress:0.0 animated:NO];
    [self.bottomView insertSubview:self.loadingProgress belowSubview:self.progressSlider];
    
    
    self.leftTimeLabel = [self labelWithTextAlignment:NSTextAlignmentLeft textColor:[UIColor whiteColor] fontSize:11];
    [self.bottomView addSubview:self.leftTimeLabel];
    self.rightTimeLabel = [self labelWithTextAlignment:NSTextAlignmentRight textColor:[UIColor whiteColor] fontSize:11];
    [self.bottomView addSubview:self.rightTimeLabel];
}

- (void)setUpLayoutWithFrame:(CGRect)frame
{
    CGFloat w,h;
    w = frame.size.width;
    h = frame.size.height;
    self.playerLayer.frame = CGRectMake(0, 0, w, h);
    self.frame = frame;
    self.loadingView.center = self.center;
    
    CGFloat topViewW = w;
    CGFloat topViewH = 40;
    self.topView.frame = CGRectMake(0, 0, topViewW, topViewH);
    
    CGFloat titleLabelW = topViewW - 90;
    CGFloat titleLabelH = topViewH;
    self.titleLabel.frame = CGRectMake((topViewW - titleLabelW) / 2, (topViewH - titleLabelH) / 2, titleLabelW, titleLabelH);
    
    self.closeBtn.frame = CGRectMake(5, 5, 30, 30);
    
    CGFloat bottomViewH = 40;
    CGFloat bottomViewW = w;
    self.bottomView.frame = CGRectMake(0, h - bottomViewH, bottomViewW , bottomViewH);
    
    self.playerControlBtn.frame = CGRectMake(0, CGRectGetHeight(self.bottomView.frame) - 40, 40, 40);
    
    CGFloat progressSliderDefaultH = self.progressSlider.frame.size.height;
    CGFloat progressSliderW = bottomViewW - 90;
    CGRect progressSliderFrame = CGRectMake((bottomViewW - progressSliderW) / 2, (bottomViewH - progressSliderDefaultH) / 2, progressSliderW, progressSliderDefaultH);
    self.progressSlider.frame = progressSliderFrame;
    
    CGFloat loadingProgressH = 2;
    // x + 2 , w - 2, 是为了修复系统的UIbug. 既: 在loadingProgress和progressSlider的x值一致的情况下, loadingProgress会比progressSlider的进度条偏左.
    self.loadingProgress.frame = CGRectMake(progressSliderFrame.origin.x + 2,progressSliderFrame.origin.y + (progressSliderFrame.size.height - loadingProgressH) / 2, progressSliderFrame.size.width - 2, loadingProgressH);
    
    CGFloat timeLabelW = bottomViewW - 90;
    CGFloat timeLabelH = 20;
    self.leftTimeLabel.frame = CGRectMake((bottomViewW - titleLabelW) / 2, bottomViewH - timeLabelH, timeLabelW, timeLabelH);
    self.rightTimeLabel.frame = CGRectMake((bottomViewW - titleLabelW) / 2, bottomViewH - timeLabelH, timeLabelW, timeLabelH);
    
    [self bringSubviewToFront:self.loadingView];
}

- (void)setPlayerControlStatusPaused:(BOOL)Paused
{
    self.playerControlBtn.selected = Paused;
}

- (void)didStartDragProgressSlider:(UISlider *)sender
{
    _isProgerssSliderActivity = YES;
}

- (void)didClickProgressSlider:(UISlider *)sender
{
    _isProgerssSliderActivity = NO;
    if ([self eventControlCanCall:@selector(didClickPlayerViewProgressSlider:)]) {
        [self.eventControl didClickPlayerViewProgressSlider:sender];
    }
}

- (void)didTapProgerssSlider:(UIGestureRecognizer *)tap
{
    CGPoint touchLocation = [tap locationInView:self.progressSlider];
    CGFloat value = (self.progressSlider.maximumValue - self.progressSlider.minimumValue) * (touchLocation.x/self.progressSlider.frame.size.width);
    [self.progressSlider setValue:value animated:YES];
    _isProgerssSliderActivity = NO;
    if ([self eventControlCanCall:@selector(didTapPlayerViewProgressSlider:)]) {
        [self.eventControl didTapPlayerViewProgressSlider:self.progressSlider];
    }
}

- (void)didClickPlayerControlButton:(UIButton *)sender
{
    if ([self eventControlCanCall:@selector(didClickPlayerViewPlayerControlButton:)]) {
        [self.eventControl didClickPlayerViewPlayerControlButton:sender];
    }
}

- (void)colseTheVideo:(UIButton *)sender
{
    if ([self eventControlCanCall:@selector(didClickPlayerViewCloseButton:)]) {
        [self.eventControl didClickPlayerViewCloseButton:sender];
    }
}

- (void)changeToSuspendTypeWithFrame:(CGRect)suspendFrame
{
    self.transform = CGAffineTransformIdentity;
    
    [self setUpLayoutWithFrame:suspendFrame];
    
    CGFloat w = suspendFrame.size.width;
    CGFloat h = suspendFrame.size.height;
    
    CGFloat topViewH = 40;
    CGFloat topViewW = w;
    self.topView.frame = CGRectMake(0, 0, topViewW, topViewH);
    CGFloat titleLabelHeight = CGRectGetHeight(self.titleLabel.frame);
    self.titleLabel.frame = CGRectMake(45, (topViewH - titleLabelHeight) / 2, topViewW - 90, titleLabelHeight);
    
    CGFloat bottomViewH = 40;
    self.bottomView.frame = CGRectMake(0, h - bottomViewH, w, bottomViewH);
    
}

- (void)updateBufferingProgressWithCurrentLoadedTime:(NSTimeInterval)currentLoadedTime duration:(NSTimeInterval)duration
{
    [self.loadingProgress setProgress:currentLoadedTime/duration animated:NO];
}

- (void)setFrame:(CGRect)frame
{
    if (!CGRectEqualToRect(self.frame, frame)) {
        [super setFrame:frame];
        [self setUpLayoutWithFrame:frame];
    }
}

- (BOOL)eventControlCanCall:(SEL)method
{
    return [self.eventControl conformsToProtocol:@protocol(YCPlayerViewEventControlDelegate)] && [self.eventControl respondsToSelector:method];
}

- (NSBundle *)currentBundle
{
    NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"YCPlayerManager" withExtension:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
    return bundle;
}

- (UIImage *)imageWithImageName:(NSString *)imageName
{
    int scale =  [UIScreen mainScreen].scale;
    NSString *scaleSuffix = [NSString stringWithFormat:@"@%dx",scale];
    if (![imageName hasSuffix:scaleSuffix]) {
        imageName = [imageName stringByAppendingString:scaleSuffix];
    }
    return [UIImage imageWithContentsOfFile:[self.currentBundle pathForResource:imageName ofType:@"png"]];
}

- (UILabel *)labelWithTextAlignment:(NSTextAlignment)textAlignment textColor:(UIColor *)textColor fontSize:(CGFloat)fontSize
{
    UILabel *label = [[UILabel alloc]init];
    label.textAlignment = textAlignment;
    label.textColor = textColor;
    label.font = [UIFont systemFontOfSize:fontSize];
    return label;
}

- (NSString *)changeToStringByTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    return [[self dateFormatter] stringFromDate:d];
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

@end
