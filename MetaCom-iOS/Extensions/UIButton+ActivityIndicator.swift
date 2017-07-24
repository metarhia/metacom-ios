//
//  UIButton+ActivityIndicator.swift
//  MetaCom-iOS
//
//  Created by Andrew Visotskyy on 21.02.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

extension UIButton {
  
  private func showActivityIndicator() {
    
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    // TODO: - Should come with better sollution
    func searchBackground(of indicatorView: UIActivityIndicatorView) -> UIColor {
      let indicatorSuperview = indicatorView.superview
      let color = (indicatorSuperview != nil) ? indicatorSuperview?.backgroundColor : .white
      return color ?? searchBackground(of: indicatorView)
    }
    
    indicator.frame = bounds
    indicator.backgroundColor = searchBackground(of: indicator)
    indicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
    indicator.startAnimating()
    
    addSubview(indicator)
  }
  
  private func hideActivityIndicator() {
    
    let indicator = subviews.first(where: { $0 is UIActivityIndicatorView }) as? UIActivityIndicatorView
    indicator?.stopAnimating()
    indicator?.removeFromSuperview()
  }
  
  public var isActivityIndicatorVisible: Bool {
    get {
      return subviews.first(where: { $0 is UIActivityIndicatorView }) != nil
    }
    set(isVisible) {
      
      guard isActivityIndicatorVisible != isVisible else {
        return
      }
      
      isVisible ? showActivityIndicator() : hideActivityIndicator()
    }
  }
}
