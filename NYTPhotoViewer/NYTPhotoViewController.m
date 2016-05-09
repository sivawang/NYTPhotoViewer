//
//  NYTPhotoViewController.m
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/11/15.
//
//

#import "NYTPhotoViewController.h"
#import "NYTPhoto.h"
#import "NYTScalingImageView.h"

#ifdef ANIMATED_GIF_SUPPORT
#import <FLAnimatedImage/FLAnimatedImage.h>
#endif

#import <DACircularProgress/DACircularProgressView.h>

NSString * const NYTPhotoViewControllerPhotoImageUpdatedNotification = @"NYTPhotoViewControllerPhotoImageUpdatedNotification";
NSString * const NYTPhotoViewControllerPhotoProgressUpdatedNotification = @"NYTPhotoViewControllerPhotoProgressUpdatedNotification";

@interface NYTPhotoViewController () <UIScrollViewDelegate>

@property (nonatomic) id <NYTPhoto> photo;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@property (nonatomic) NYTScalingImageView *scalingImageView;
@property (nonatomic) UIView *loadingView;
@property (nonatomic) NSNotificationCenter *notificationCenter;
@property (nonatomic) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic) DACircularProgressView *progressView;

@end

@implementation NYTPhotoViewController

#pragma mark - NSObject

- (void)dealloc {
    _scalingImageView.delegate = nil;
    
    [_notificationCenter removeObserver:self];
}

#pragma mark - UIViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithPhoto:nil loadingView:nil notificationCenter:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self commonInitWithPhoto:nil loadingView:nil notificationCenter:nil];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.notificationCenter addObserver:self selector:@selector(photoImageUpdatedWithNotification:) name:NYTPhotoViewControllerPhotoImageUpdatedNotification object:nil];
    [self.notificationCenter addObserver:self selector:@selector(photoProgressUpdatedWithNotification:) name:NYTPhotoViewControllerPhotoProgressUpdatedNotification object:nil];
    
    self.scalingImageView.frame = self.view.bounds;
    [self.view addSubview:self.scalingImageView];
    
    [self.view addSubview:self.loadingView];
    [self.loadingView sizeToFit];
    
    [self.view addGestureRecognizer:self.doubleTapGestureRecognizer];
    [self.view addGestureRecognizer:self.longPressGestureRecognizer];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.scalingImageView.frame = self.view.bounds;
    
    [self.loadingView sizeToFit];
    self.loadingView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
}

#pragma mark - NYTPhotoViewController

- (instancetype)initWithPhoto:(id <NYTPhoto>)photo loadingView:(UIView *)loadingView notificationCenter:(NSNotificationCenter *)notificationCenter {
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        [self commonInitWithPhoto:photo loadingView:loadingView notificationCenter:notificationCenter];
    }
    
    return self;
}

- (void)commonInitWithPhoto:(id <NYTPhoto>)photo loadingView:(UIView *)loadingView notificationCenter:(NSNotificationCenter *)notificationCenter {
    _photo = photo;
    
    if (photo.imageData) {
        _scalingImageView = [[NYTScalingImageView alloc] initWithImageData:photo.imageData frame:CGRectZero];
    }
    else {
        UIImage *photoImage = photo.image ?: photo.placeholderImage;
        _scalingImageView = [[NYTScalingImageView alloc] initWithImage:photoImage frame:CGRectZero];
        
        if (!photo.image) {
            [self setupLoadingView:loadingView];
        }
    }
    
    _scalingImageView.delegate = self;

    _notificationCenter = notificationCenter;

    [self setupGestureRecognizers];
}

- (DACircularProgressView *)progressView {
    if (_progressView == nil) {
        CGRect rect = CGRectMake(0, 0, 54, 54);
        _progressView = [[DACircularProgressView alloc] initWithFrame:rect];
        _progressView.backgroundColor = [UIColor clearColor];
        _progressView.progressTintColor = [UIColor whiteColor];
        _progressView.progress = 0.66;
    }
    
    return _progressView;
}

- (void)setupLoadingView:(UIView *)loadingView {
    self.loadingView = loadingView;
    if (!loadingView) {
//        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
//        [activityIndicator startAnimating];
//        self.loadingView = activityIndicator;
        
        // Special logic for photo uploading progress.
        [self.progressView setIndeterminate:1];
        [self updateProgress:self.photo.progress];
        
        self.loadingView = self.progressView;
    }
}

- (void)photoImageUpdatedWithNotification:(NSNotification *)notification {
    id <NYTPhoto> photo = notification.object;
    if ([photo conformsToProtocol:@protocol(NYTPhoto)] && [photo isEqual:self.photo]) {
        [self updateImage:photo.image imageData:photo.imageData];
    }
}

- (void)photoProgressUpdatedWithNotification:(NSNotification *)notification {
    id <NYTPhoto> photo = notification.object;
    if ([photo conformsToProtocol:@protocol(NYTPhoto)] && [photo isEqual:self.photo]) {
        [self updateProgress:photo.progress];
    }
}

- (void)updateProgress:(CGFloat)progress {
    if (progress < 0) {
        [self.progressView setIndeterminate:0];
        
        //#bc204b
        UIColor *color = [UIColor colorWithRed:0xbc/255.0 green:0x20/255.0 blue:0x4b/255.0 alpha:1.0];
        [self.progressView setIndeterminate:0];
        [self.progressView setProgress:0.33];
        [self.progressView setProgressTintColor:color];
    } else {
        if (progress > 0) {
            [self.progressView setIndeterminate:0];
        }
        [self.progressView setProgress:progress];
    }
    
    [self.photo setProgress:progress];
}

- (void)updateImage:(UIImage *)image imageData:(NSData *)imageData {
    if (imageData) {
        [self.scalingImageView updateImageData:imageData];
    }
    else {
        [self.scalingImageView updateImage:image];
    }
    
    if (imageData || image) {
        [self.loadingView removeFromSuperview];
    } else {
        [self.view addSubview:self.loadingView];
    }
}

#pragma mark - Gesture Recognizers

- (void)setupGestureRecognizers {
    self.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTapWithGestureRecognizer:)];
    self.doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressWithGestureRecognizer:)];
}

- (void)didDoubleTapWithGestureRecognizer:(UITapGestureRecognizer *)recognizer {
    CGPoint pointInView = [recognizer locationInView:self.scalingImageView.imageView];
    
    CGFloat newZoomScale = self.scalingImageView.maximumZoomScale;

    if (self.scalingImageView.zoomScale >= self.scalingImageView.maximumZoomScale
        || ABS(self.scalingImageView.zoomScale - self.scalingImageView.maximumZoomScale) <= 0.01) {
        newZoomScale = self.scalingImageView.minimumZoomScale;
    }
    
    CGSize scrollViewSize = self.scalingImageView.bounds.size;
    
    CGFloat width = scrollViewSize.width / newZoomScale;
    CGFloat height = scrollViewSize.height / newZoomScale;
    CGFloat originX = pointInView.x - (width / 2.0);
    CGFloat originY = pointInView.y - (height / 2.0);
    
    CGRect rectToZoomTo = CGRectMake(originX, originY, width, height);
    
    [self.scalingImageView zoomToRect:rectToZoomTo animated:YES];
}

- (void)didLongPressWithGestureRecognizer:(UILongPressGestureRecognizer *)recognizer {
    if ([self.delegate respondsToSelector:@selector(photoViewController:didLongPressWithGestureRecognizer:)]) {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            [self.delegate photoViewController:self didLongPressWithGestureRecognizer:recognizer];
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.scalingImageView.imageView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    scrollView.panGestureRecognizer.enabled = YES;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    // There is a bug, especially prevalent on iPhone 6 Plus, that causes zooming to render all other gesture recognizers ineffective.
    // This bug is fixed by disabling the pan gesture recognizer of the scroll view when it is not needed.
    if (scrollView.zoomScale == scrollView.minimumZoomScale) {
        scrollView.panGestureRecognizer.enabled = NO;
    }
}

@end
