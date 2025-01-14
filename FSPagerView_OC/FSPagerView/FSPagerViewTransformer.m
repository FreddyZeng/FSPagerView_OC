//
//  FSPagerViewTransformer.m
//  FSPagerView_OC
//
//  Created by  skyhome on 2019/6/14.
//  Copyright © 2019 mobile. All rights reserved.
//

#import "FSPagerViewTransformer.h"
#import "FSPagerView.h"

@interface FSPagerViewTransformer()

@property (nonatomic, assign, readwrite) FSPagerViewTransformerType type;

@end

@implementation FSPagerViewTransformer


- (instancetype)initWithType:(FSPagerViewTransformerType)type {
    self = [super init];
    [self commonInit];
    self.type = type;
    
    switch (type) {
        case FSPagerViewTransformerTypeZoomOut:
            self.minimumScale = 0.85;
            break;
        case FSPagerViewTransformerTypeDepth:
            self.minimumScale = 0.5;
            break;
            
        default:
            break;
    }
    
    return self;
}

- (instancetype)init {
    self = [super init];
    [self commonInit];
    
    return self;
}

- (void)commonInit {
    self.minimumScale = 0.65;
    self.minimumAlpha = 0.6;
}

- (void)applyTransformToAttributes:(FSPagerViewLayoutAttributes *)attributes {
    FSPagerView *pagerView = self.pagerView;
    if (!pagerView) {
        return;
    }
    
    CGFloat position = attributes.position;
    FSPagerViewScrollDirection scrollDirection = pagerView.scrollDirection;
    CGFloat itemSpacing = (scrollDirection == FSPagerViewScrollDirectionHorizontal ? attributes.bounds.size.width : attributes.bounds.size.height) + [self proposedInteritemSpacing];
    switch (self.type) {
        case FSPagerViewTransformerTypeCrossFading:
        {
            NSInteger zIndex = 0;
            CGFloat alpha = 0;
            CGAffineTransform transform = CGAffineTransformIdentity;
            if (scrollDirection == FSPagerViewScrollDirectionHorizontal) {
                transform.tx = -itemSpacing * position;
            } else {
                transform.ty = -itemSpacing * position;
            }
            
            if (fabs(position) <= 1) { // [-1,1]
                // Use the default slide transition when moving to the left page
                alpha = 1 - fabs(position);
                zIndex = 1;
            } else { // (1,+Infinity]
                // This page is way off-screen to the right.
                alpha = 0;
                zIndex = NSIntegerMin;
            }
            
            attributes.alpha = alpha;
            attributes.transform = transform;
            attributes.zIndex = zIndex;
        }
            break;
        case FSPagerViewTransformerTypeZoomOut:
        {
            CGFloat alpha = 0;
            CGAffineTransform transform = CGAffineTransformIdentity;
            if (-INFINITY <= position && position < -1) { // [-Infinity,-1)
                // This page is way off-screen to the left.
                alpha = 0;
            } else if (-1 <= position && position <= 1) {// [-1,1]
                // Modify the default slide transition to shrink the page as well
                CGFloat scaleFactor = MAX(self.minimumScale, 1 - fabs(position));
                transform.a = scaleFactor;
                transform.d = scaleFactor;
                if (scrollDirection == FSPagerViewScrollDirectionHorizontal) {
                    CGFloat vertMargin = attributes.bounds.size.height * (1 - scaleFactor) / 2;
                    CGFloat horzMargin = itemSpacing * (1 - scaleFactor) / 2;
                    transform.tx = position < 0 ? (horzMargin - vertMargin*2) : (-horzMargin + vertMargin*2);
                } else {
                    CGFloat horzMargin = attributes.bounds.size.width * (1 - scaleFactor) / 2;
                    CGFloat vertMargin = itemSpacing * (1 - scaleFactor) / 2;
                    transform.ty = position < 0 ? (vertMargin - horzMargin*2) : (-vertMargin + horzMargin*2);
                }
                // Fade the page relative to its size.
                alpha = self.minimumAlpha + (scaleFactor-self.minimumScale)/(1-self.minimumScale)*(1-self.minimumAlpha);
            } else if (1 < position && position <= INFINITY) { // (1,+Infinity]
                // This page is way off-screen to the right.
                alpha = 0;
            }
            attributes.alpha = alpha;
            attributes.transform = transform;
             break;
        }
        case FSPagerViewTransformerTypeDepth:
        {
            NSInteger zIndex = 0;
            CGFloat alpha = 0;
            CGAffineTransform transform = CGAffineTransformIdentity;
            if (-INFINITY <= position && position < -1) { // [-Infinity,-1)
                // This page is way off-screen to the left.
                alpha = 0;
                zIndex = 0;
            } else if (-1 <= position && position <= 0) { // [-1,0]
                // Use the default slide transition when moving to the left page
                alpha = 1;
                transform.tx = 0;
                transform.a = 1;
                transform.d = 1;
                zIndex = 1;
            }  else if (0 < position && position < 1) { // (0,1)
                // Fade the page out.
                alpha = 1 - position;
                // Counteract the default slide transition
                if (scrollDirection == FSPagerViewScrollDirectionHorizontal) {
                    transform.tx = itemSpacing * -position;
                } else {
                    transform.ty = itemSpacing * -position;
                }

                // Scale the page down (between minimumScale and 1)
                CGFloat scaleFactor = self.minimumScale + (1.0 - self.minimumScale) * (1.0 - fabs(position));
                transform.a = scaleFactor;
                transform.d = scaleFactor;
                zIndex = 0;
            } else if (1 <= position && position <= INFINITY) { // (1,+Infinity]
                // This page is way off-screen to the right.
                alpha = 0;
                zIndex = 0;
            }
            attributes.alpha = alpha;
            attributes.transform = transform;
            attributes.zIndex = zIndex;
            
            break;
        }
        case FSPagerViewTransformerTypeOverlap:
        {
            if (scrollDirection != FSPagerViewScrollDirectionHorizontal) {
                return;
            }
            CGFloat scale = MAX(1 - (1-self.minimumScale) * fabs(position), self.minimumScale);
            CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
            attributes.transform = transform;
            CGFloat alpha = (self.minimumAlpha + (1-fabs(position))*(1-self.minimumAlpha));
            attributes.alpha = alpha;
            NSInteger zIndex = (1-fabs(position)) * 10;
            attributes.zIndex = zIndex;
            break;
        }
        case FSPagerViewTransformerTypeLinear:
        {
            if (scrollDirection != FSPagerViewScrollDirectionHorizontal) {
                return;
            }
            CGFloat scale = MAX(1 - (1-self.minimumScale) * fabs(position), self.minimumScale);
            CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
            attributes.transform = transform;
            CGFloat alpha = (self.minimumAlpha + (1-fabs(position))*(1-self.minimumAlpha));
            attributes.alpha = alpha;
            NSInteger zIndex = (1-fabs(position)) * 10;
            attributes.zIndex = zIndex;
            break;
        }
        case FSPagerViewTransformerTypeCoverFlow:
        {
            if (scrollDirection != FSPagerViewScrollDirectionHorizontal) {
                return;
            }
            CGFloat position1 = MIN(MAX(-position,-1) ,1);
            CGFloat rotation = sin(position1*(M_PI)*0.5)*(M_PI)*0.25*1.5;
            CGFloat translationZ = -itemSpacing * 0.5 * fabs(position1);
            CATransform3D transform3D = CATransform3DIdentity;
            transform3D.m34 = -0.002;
            transform3D = CATransform3DRotate(transform3D, rotation, 0, 1, 0);
            transform3D = CATransform3DTranslate(transform3D, 0, 0, translationZ);
            attributes.zIndex = 100 - (int)fabs(position1);
            attributes.transform3D = transform3D;
            break;
        }
        case FSPagerViewTransformerTypeFerrisWheel:
        {
            if (scrollDirection != FSPagerViewScrollDirectionHorizontal) {
                return;
            }
            // http://ronnqvi.st/translate-rotate-translate/
            NSInteger zIndex = 0;
            CGAffineTransform transform = CGAffineTransformIdentity;
            if (-5 <= position && position <= 5) {
                CGFloat itemSpacing = attributes.bounds.size.width+[self proposedInteritemSpacing];
                CGFloat count = 14;
                CGFloat circle = M_PI * 2.0;
                CGFloat radius = itemSpacing * count / circle;
                CGFloat ty = radius * -1;
                CGFloat theta = circle / count;
                CGFloat rotation = position * theta * -1;
                transform = CGAffineTransformTranslate(transform, -position*itemSpacing, ty);
                transform = CGAffineTransformRotate(transform, rotation);
                transform = CGAffineTransformTranslate(transform, 0, -ty);
                zIndex = (int)((4.0-(int)fabs(position)*10));
            }
            
            attributes.alpha = fabs(position) < 0.5 ? 1 : self.minimumAlpha;
            attributes.transform = transform;
            attributes.zIndex = zIndex;
            
            break;
        }
        case FSPagerViewTransformerTypeInvertedFerrisWheel:
        {
            if (scrollDirection != FSPagerViewScrollDirectionHorizontal) {
                return;
            }
            // http://ronnqvi.st/translate-rotate-translate/
            NSInteger zIndex = 0;
            CGAffineTransform transform = CGAffineTransformIdentity;
            if (-5 <= position && position <= 5) {
                CGFloat itemSpacing = attributes.bounds.size.width+[self proposedInteritemSpacing];
                CGFloat count = 14;
                CGFloat circle = M_PI * 2.0;
                CGFloat radius = itemSpacing * count / circle;
                CGFloat ty = radius * 1;
                CGFloat theta = circle / count;
                CGFloat rotation = position * theta * 1;
                transform = CGAffineTransformTranslate(transform, -position*itemSpacing, ty);
                transform = CGAffineTransformRotate(transform, rotation);
                transform = CGAffineTransformTranslate(transform, 0, -ty);
                zIndex = (int)((4.0-(int)fabs(position)*10));
            }
            
            attributes.alpha = fabs(position) < 0.5 ? 1 : self.minimumAlpha;
            attributes.transform = transform;
            attributes.zIndex = zIndex;
            break;
        }
        case FSPagerViewTransformerTypeCubic:
        {
            if (-INFINITY <= position && position <= -1) { // [-Infinity,-1]
                // This page is way off-screen to the left.
                attributes.alpha = 0;
            } else if (-1 < position && position < 1) { // (-1,1)
                attributes.alpha = 1;
                attributes.zIndex = (int)((1-position) * 10);
                CGFloat direction = position < 0 ? 1 : -1;
                CGFloat theta = position * M_PI * 0.5 * (scrollDirection == FSPagerViewScrollDirectionHorizontal ? 1 : -1);
                CGFloat radius = scrollDirection == FSPagerViewScrollDirectionHorizontal ? attributes.bounds.size.width : attributes.bounds.size.height;
                CATransform3D transform3D = CATransform3DIdentity;
                transform3D.m34 = -0.002;
                if (scrollDirection == FSPagerViewScrollDirectionHorizontal) {
                    // ForwardX -> RotateY -> BackwardX
                    attributes.center = CGPointMake(direction*radius*0.5 + attributes.center.x, attributes.center.y);  // ForwardX
                    transform3D = CATransform3DRotate(transform3D, theta, 0, 1, 0); // RotateY
                    transform3D = CATransform3DTranslate(transform3D,-direction*radius*0.5, 0, 0); // BackwardX
                } else {
                    // ForwardY -> RotateX -> BackwardY
                    attributes.center = CGPointMake(attributes.center.x, direction*radius*0.5 + attributes.center.y);
                    transform3D = CATransform3DRotate(transform3D, theta, 1, 0, 0); // RotateX
                    transform3D = CATransform3DTranslate(transform3D,0, -direction*radius*0.5, 0); // BackwardY
                }
                attributes.transform3D = transform3D;
            } else if (1 <= position && position <= INFINITY) { // [1,+Infinity]
                // This page is way off-screen to the right.
                attributes.alpha = 0;
            } else {
                attributes.alpha = 0;
                attributes.zIndex = 0;
            }
            break;
        }
        case FSPagerViewTransformerTypeHorizontalOnlyAlpha:
        {
            if (scrollDirection != FSPagerViewScrollDirectionHorizontal) {
                return;
            }
            CGFloat alpha = (self.minimumAlpha + (1-fabs(position))*(1-self.minimumAlpha));
            attributes.alpha = alpha;
            break;
        }
        default:
            break;
    }
}

// An interitem spacing proposed by transformer class. This will override the default interitemSpacing provided by the pager view.
- (CGFloat)proposedInteritemSpacing {
    FSPagerView *pagerView = self.pagerView;
    if (!pagerView) {
        return 0;
    }
    
    FSPagerViewScrollDirection scrollDirection = pagerView.scrollDirection;
    switch (self.type) {
        case FSPagerViewTransformerTypeOverlap:
        {
            if (scrollDirection != FSPagerViewScrollDirectionHorizontal) {
                return 0;
            }
            
            return pagerView.itemSize.width * -self.minimumScale * 0.6;
        }
            break;
        case FSPagerViewTransformerTypeLinear:
        {
            if (scrollDirection != FSPagerViewScrollDirectionHorizontal) {
                return 0;
            }
            
            return pagerView.itemSize.width * -self.minimumScale * 0.2;
        }
            break;
        case FSPagerViewTransformerTypeCoverFlow:
        {
            if (scrollDirection != FSPagerViewScrollDirectionHorizontal) {
                return 0;
            }
            
            return -pagerView.itemSize.width * sin(M_PI*0.25*0.25*3.0);
        }
            break;
        case FSPagerViewTransformerTypeFerrisWheel:
        {
            if (scrollDirection != FSPagerViewScrollDirectionHorizontal) {
                return 0;
            }
            
            return -pagerView.itemSize.width * 0.15;
        }
            break;
        case FSPagerViewTransformerTypeInvertedFerrisWheel:
        {
            if (scrollDirection != FSPagerViewScrollDirectionHorizontal) {
                return 0;
            }
            
            return -pagerView.itemSize.width * 0.15;
        }
            break;
        case FSPagerViewTransformerTypeCubic:
        {
            return 0;
        }
            break;
        case FSPagerViewTransformerTypeHorizontalOnlyAlpha:
        {
            return pagerView.interitemSpacing;
        }
            break;
        default:
            break;
    }
    
    
    return pagerView.interitemSpacing;
}

@end
