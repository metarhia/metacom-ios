//
//  CompletionsView.swift
//  MetaCom-iOS
//
//  Created by iKing on 04.10.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

// MARK: - CompletionsViewDelegate

protocol CompletionsViewDelegate: class {
	
	func completionsView(_ completionsView: CompletionsView, didPickItemAt index: Int)
}

// MARK: - CompletionsView

class CompletionsView: UIView {
	
	var completions: [CustomStringConvertible] = [] {
		didSet {
			collectionView?.reloadData()
			updateCollectionViewInsets()
			updateInfoLabel()
		}
	}
	
	weak var delegate: CompletionsViewDelegate?
	
	private weak var collectionView: UICollectionView!
	private weak var infoLabel: UILabel!
	
	convenience init() {
		self.init(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	private func setup() {
		let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
		blur.frame = bounds
		blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		addSubview(blur)
		
		let infoLabel = UILabel(frame: bounds)
		infoLabel.textAlignment = .center
		infoLabel.textColor = .white
		infoLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		infoLabel.font = UIFont.systemFont(ofSize: 16)
		infoLabel.text = "no_avilable_completions".localized
		addSubview(infoLabel)
		
		let flowLayout = UICollectionViewFlowLayout()
		flowLayout.scrollDirection = .horizontal
		flowLayout.estimatedItemSize = CGSize(width: 0, height: 1)
		let collectionView = UICollectionView(frame: bounds, collectionViewLayout: flowLayout)
		collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		collectionView.register(CompletionCell.self, forCellWithReuseIdentifier: "completionCell")
		collectionView.backgroundColor = .clear
		collectionView.showsHorizontalScrollIndicator = false
		collectionView.showsVerticalScrollIndicator = false
		collectionView.delaysContentTouches = false
		collectionView.dataSource = self
		collectionView.delegate = self
		addSubview(collectionView)
		
		self.collectionView = collectionView
		self.infoLabel = infoLabel
		updateInfoLabel()
	}
	
	private func updateInfoLabel() {
		infoLabel?.isHidden = !completions.isEmpty
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		updateCollectionViewInsets()
		if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
			flowLayout.estimatedItemSize.height = bounds.height - 4 * 2
		}
	}
	
	private func updateCollectionViewInsets() {
		guard let collectionView = collectionView else {
			return
		}
		
		UIView.setAnimationsEnabled(false)
		collectionView.collectionViewLayout.invalidateLayout()
		collectionView.layoutIfNeeded()
		UIView.setAnimationsEnabled(true)
		
		let containerWidth = collectionView.bounds.width
		let contentWidth = collectionView.contentSize.width
		var horizontalInset: CGFloat = 0.0
		if contentWidth < containerWidth {
			horizontalInset = (containerWidth - contentWidth) / 2.0
		}
		
		collectionView.contentInset = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)
	}
}

// MARK: - UICollectionViewDataSource

extension CompletionsView: UICollectionViewDataSource {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return completions.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "completionCell", for: indexPath)
		
		if let cell = cell as? CompletionCell {
			cell.text = completions[indexPath.item].description
		}
		
		return cell
	}
}

// MARK: - UICollectionViewDelegate

extension CompletionsView: UICollectionViewDelegate {
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: true)
		delegate?.completionsView(self, didPickItemAt: indexPath.item)
	}
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CompletionsView: UICollectionViewDelegateFlowLayout {
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
	}
}

// MARK: - CompletionCell

private class CompletionCell: UICollectionViewCell {
	
	private weak var label: UILabel!
	
	var text: String = "" {
		didSet {
			updateLabel()
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	private func setup() {
		layer.cornerRadius = 4
		clipsToBounds = true
		
		let label = UILabel(frame: bounds)
		label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		label.textAlignment = .center
		label.textColor = .white
		addSubview(label)
		
		self.label = label
		
		updateBackground()
	}
	
	override var isHighlighted: Bool {
		didSet {
			updateBackground()
		}
	}
	
	private func updateLabel() {
		label?.text = text
	}
	
	private func updateBackground() {
		backgroundColor = isHighlighted ? .gray : .darkGray
	}
	
	override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		setNeedsLayout()
		layoutIfNeeded()
		
		let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
		
		let size = label.systemLayoutSizeFitting(.zero)
		attributes.frame.size.width = size.width + 12
		
		return attributes
	}
	
}
