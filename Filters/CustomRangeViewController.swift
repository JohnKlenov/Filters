//
//  CustomRangeViewController.swift
//  Filters
//
//  Created by Evgenyi on 14.09.23.
//

import UIKit

enum StateFirstStart {
    case nul
    case reset
    case firstStart
}

protocol CustomTabBarViewDelegate: AnyObject {
    func customTabBarViewDidTapButton(_ tabBarView: CustomTabBarView)
}

class CustomRangeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var dataSource = [String:[String]]() {
        didSet {
            collectionView.reloadData()
        }
    }
    var allProducts:[Product] = []
    var filterProducts:[Product] = [] {
        didSet {
            customTabBarView.setCounterButton(count: filterProducts.count)
            if filterProducts.isEmpty {
                isForcedPrice = true
                rangeSlider.isEnabled = false
                rangeView.updateLabels(lowerValue: 0, upperValue: 0)
            } else {
                calculatePriceForFilterProducts(products: filterProducts)
            }
        }
    }
    
    var fixedPriceFilterProducts:[Product] = [] {
        didSet {
            customTabBarView.setCounterButton(count: fixedPriceFilterProducts.count)
        }
    }
    var stateReturnFilterProduct: StateFirstStart = .nul
    
    var selectedItem: [IndexPath:String] = [:]
    var isForcedPrice: Bool = false
    var isFixedPriceProducts:Bool = false
    
    var dataManager = FactoryProducts.shared
    
    // MARK: property for fixed filter screen -
    
    var isActiveScreenFilter:Bool = false
    var minimumValue: Double?
    var maximumValue: Double?
    var lowerValue: Double?
    var upperValue: Double?
    
    var countFilterProduct:Int?
    
    private let collectionView: UICollectionView = {
        
        let layout = UserProfileTagsFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    let closeButton: UIButton = {
        var configButton = UIButton.Configuration.plain()
        configButton.title = "Close"
        configButton.baseForegroundColor = UIColor.systemPurple
        configButton.titleAlignment = .leading
        configButton.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incomig in

            var outgoing = incomig
            outgoing.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            return outgoing
        }
        var button = UIButton(configuration: configButton)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let resetButton: UIButton = {
        var configButton = UIButton.Configuration.plain()
        configButton.title = "Reset"
        configButton.baseForegroundColor = UIColor.systemPurple
        configButton.titleAlignment = .trailing
        configButton.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incomig in

            var outgoing = incomig
            outgoing.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            return outgoing
        }
        var button = UIButton(configuration: configButton)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let customTabBarView: CustomTabBarView = {
        let view = CustomTabBarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let rangeView = RangeView()
    let rangeSlider = RangeSlider(frame: .zero)

    weak var delegate:CustomRangeViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        
        collectionView.dataSource = self
        collectionView.delegate = self
        customTabBarView.delegate = self
        collectionView.backgroundColor = .clear

        collectionView.register(MyCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(HeaderFilterCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderFilterCollectionReusableView.headerIdentifier)
        
        view.addSubview(rangeView)
        view.addSubview(rangeSlider)
        view.addSubview(collectionView)
        view.addSubview(customTabBarView)
        configureNavigationBar(largeTitleColor: UIColor.label, backgoundColor: UIColor.secondarySystemBackground, tintColor: UIColor.label, title: "Filters", preferredLargeTitle: false)
        configureNavigationItem()
        rangeSlider.addTarget(self, action: #selector(rangeSliderValueChanged(rangeSlider:)), for: .valueChanged)
        rangeSlider.addTarget(self, action: #selector(rangeSliderTouchUpInside(rangeSlider:)), for: .touchUpInside)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: rangeSlider.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: customTabBarView.topAnchor)
        ])
        
        NSLayoutConstraint.activate([
            customTabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        if !isActiveScreenFilter {
            calculateDataSource(products: allProducts)
            customTabBarView.setCounterButton(count: allProducts.count)
            stateReturnFilterProduct = .firstStart
        } else {
            customTabBarView.setCounterButton(count: countFilterProduct ?? 0)
            stateReturnFilterProduct = .firstStart
            calculateDataSourceForScreenFilter(products: allProducts)
        }
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        rangeView.frame = CGRect(x: 0, y: 10, width: UIScreen.main.bounds.width, height: 90)
        rangeSlider.frame = CGRect(x: 10, y: rangeView.frame.maxY, width: UIScreen.main.bounds.width - 20, height: 30)
        
    }
    
    @objc func rangeSliderValueChanged(rangeSlider: RangeSlider) {
        if !isForcedPrice {
            rangeView.updateLabels(lowerValue: rangeSlider.lowerValue, upperValue: rangeSlider.upperValue)
        }
    }
    
    @objc func rangeSliderTouchUpInside(rangeSlider: RangeSlider) {
        
        let filteredColor = Array((selectedItem.filter { $0.key.section == 0 }).values)
        let color = filteredColor.isEmpty ? nil : filteredColor
        
        let filteredBrand = Array((selectedItem.filter { $0.key.section == 1 }).values)
        let brand = filteredBrand.isEmpty ? nil : filteredBrand
        
        let filteredMaterial = Array((selectedItem.filter { $0.key.section == 2 }).values)
        let material = filteredMaterial.isEmpty ? nil : filteredMaterial
        
        let filteredSeason = Array((selectedItem.filter { $0.key.section == 3 }).values)
        let season = filteredSeason.isEmpty ? nil : filteredSeason
        
        stateReturnFilterProduct = .nul
        isFixedPriceProducts = true
        lowerValue = rangeSlider.lowerValue
        upperValue = rangeSlider.upperValue
        fixedPriceFilterProducts = filterProductsUniversal(products: allProducts, color: color, brand: brand, material: material, season: season, minPrice: Int(rangeSlider.lowerValue), maxPrice: Int(rangeSlider.upperValue))
    }
    
    
    @objc func didTapCloseButton() {
        
        if stateReturnFilterProduct == .reset {
            delegate?.didChangedFilterProducts(filterProducts: allProducts, isActiveScreenFilter: false, isFixedPriceProducts: false, minimumValue: nil, maximumValue: nil, lowerValue: nil, upperValue: nil, countFilterProduct: nil, selectedItem: nil)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapResetButton() {
        
        // we must inform the close button that the settings have been reset
        stateReturnFilterProduct = .reset
        isActiveScreenFilter = false
        countFilterProduct = nil
        minimumValue = nil
        maximumValue = nil
        lowerValue = nil
        upperValue = nil
        rangeSlider.isEnabled = true
        isForcedPrice = false
        isFixedPriceProducts = false
        selectedItem = [:]
        
        customTabBarView.setCounterButton(count: allProducts.count)
        calculatePriceForFilterProducts(products: allProducts)
        collectionView.reloadData()
    }

    private func configureNavigationItem() {
        
        closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(didTapResetButton), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: resetButton)
    }
    
    private func configureRangeView(minimumValue:Double, maximumValue:Double) {
        rangeSlider.minimumValue = minimumValue
        rangeSlider.maximumValue = maximumValue
        rangeSlider.lowerValue = minimumValue
        rangeSlider.upperValue = maximumValue
    }
    
    private func configureRangeViewForScreenFilter(minimumValue:Double, maximumValue:Double, lowerValue:Double, upperValue:Double ) {
        rangeSlider.minimumValue = minimumValue
        rangeSlider.maximumValue = maximumValue
        rangeSlider.lowerValue = lowerValue
        rangeSlider.upperValue = upperValue
    }
    
    private func calculateDataSource(products: [Product]) {

        var minPrice = Int.max
        var maxPrice = Int.min
        var dataSource = [String: [String]]()
        var counter = 0
        for product in products {
            counter+=1
            if let color = product.color {
                dataSource["color", default: []].append(color)
            }
            if let brand = product.brand {
                dataSource["brand", default: []].append(brand)
            }
            if let material = product.material {
                dataSource["material", default: []].append(material)
            }
            if let season = product.season {
                dataSource["season", default: []].append(season)
            }
            if let price = product.price {
                
                   if price < minPrice {
                       minPrice = price
                   }
                   if price > maxPrice {
                       maxPrice = price
                   }
               }
        }
        if counter == products.count {
            for key in dataSource.keys {
                let values = Set(dataSource[key]!)
                dataSource[key] = Array(values)
                let sortValue = dataSource[key]?.sorted()
                dataSource[key] = sortValue
            }
            minimumValue = Double(minPrice)
            maximumValue = Double(maxPrice)
            configureRangeView(minimumValue: Double(minPrice), maximumValue: Double(maxPrice))
            self.dataSource = dataSource
        }
    }
    
    private func calculateDataSourceForScreenFilter(products: [Product]) {

        var dataSource = [String: [String]]()
        var counter = 0
        for product in products {
            counter+=1
            if let color = product.color {
                dataSource["color", default: []].append(color)
            }
            if let brand = product.brand {
                dataSource["brand", default: []].append(brand)
            }
            if let material = product.material {
                dataSource["material", default: []].append(material)
            }
            if let season = product.season {
                dataSource["season", default: []].append(season)
            }
        }
        if counter == products.count {
            for key in dataSource.keys {
                let values = Set(dataSource[key]!)
                dataSource[key] = Array(values)
                let sortValue = dataSource[key]?.sorted()
                dataSource[key] = sortValue
            }
           
            if isFixedPriceProducts {
                print("isFixedPriceProducts isFixedPriceProducts isFixedPriceProducts")
                if let minimumValue = minimumValue, let maximumValue = maximumValue, let lowerValue = lowerValue, let upperValue = upperValue  {
                    configureRangeViewForScreenFilter(minimumValue: minimumValue, maximumValue: maximumValue, lowerValue: lowerValue, upperValue: upperValue)
                    }
            } else {
                if let minimumValue = minimumValue, let maximumValue = maximumValue, let lowerValue = lowerValue, let upperValue = upperValue  {
                    if lowerValue != upperValue {
                        configureRangeViewForScreenFilter(minimumValue: lowerValue, maximumValue: upperValue, lowerValue: lowerValue, upperValue: upperValue)
                    } else {
                        configureRangeViewForScreenFilter(minimumValue: minimumValue, maximumValue: maximumValue, lowerValue: minimumValue, upperValue: maximumValue)
                        isForcedPrice = true
                        rangeSlider.isEnabled = false
                        rangeView.updateLabels(lowerValue: lowerValue, upperValue: upperValue)
                    }
                }
            }
            self.dataSource = dataSource
        }
    }
    
    private func calculatePriceForFilterProducts(products: [Product]) {
        
        print("calculatePriceForFilterProducts(product.count) - \(products.count)")
        var minPrice = Int.max
        var maxPrice = Int.min
        
        var counter = 0
        for product in products {
            counter+=1

            if let price = product.price {

                if price < minPrice {
                    minPrice = price
                }
                if price > maxPrice {
                    maxPrice = price
                }
            }
        }
        
        if counter == products.count {
            if minPrice != maxPrice {
                configureRangeView(minimumValue: Double(minPrice), maximumValue: Double(maxPrice))
            } else {
                isForcedPrice = true
                rangeSlider.isEnabled = false
                rangeView.updateLabels(lowerValue: Double(minPrice), upperValue: Double(maxPrice))
            }
            
        }
    }
    
    
    func filterProductsUniversal(products: [Product], color: [String]? = nil, brand: [String]? = nil, material: [String]? = nil, season: [String]? = nil, minPrice: Int? = nil, maxPrice: Int? = nil) -> [Product] {
        let filteredProducts = products.filter { product in
            var isMatched = true

            if let color = color {
                isMatched = isMatched && color.contains(product.color ?? "")
            }

            if let brand = brand {
                isMatched = isMatched && brand.contains(product.brand ?? "")
            }

            if let material = material {
                isMatched = isMatched && material.contains(product.material ?? "")
            }

            if let season = season {
                isMatched = isMatched && season.contains(product.season ?? "")
            }

            if let minPrice = minPrice {
                isMatched = isMatched && (product.price ?? -1 >= minPrice)
            }

            if let maxPrice = maxPrice {
                isMatched = isMatched && (product.price ?? 1000 <= maxPrice)
            }

            return isMatched
        }

        return filteredProducts
    }
    
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return dataSource["color"]?.count ?? 0
        case 1:
            return dataSource["brand"]?.count ?? 0
        case 2:
            return dataSource["material"]?.count ?? 0
        case 3:
            return dataSource["season"]?.count ?? 0
        default:
            print("Returned message for analytic FB Crashlytics error")
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? MyCell else {
            return UICollectionViewCell()
        }
        
        if let _ = selectedItem[indexPath] {
            cell.contentView.backgroundColor = UIColor.systemPurple
               } else {
                   cell.contentView.backgroundColor = UIColor.secondarySystemBackground
               }
        
        switch indexPath.section {
        case 0:
            let colors = dataSource["color"]
            cell.label.text = colors?[indexPath.row]
        case 1:
            let brands = dataSource["brand"]
            cell.label.text = brands?[indexPath.row]
        case 2:
            let material = dataSource["material"]
            cell.label.text = material?[indexPath.row]
        case 3:
            let season = dataSource["season"]
            cell.label.text = season?[indexPath.row]
        default:
            print("Returned message for analytic FB Crashlytics error")
        }
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        stateReturnFilterProduct = .nul
        isForcedPrice = false
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? MyCell else {
            return
        }
        
        let item = cell.label.text ?? ""
        
        if let _ = selectedItem[indexPath] {
            selectedItem[indexPath] = nil
        } else {
            selectedItem[indexPath] = item
        }
        
        let filteredColor = Array((selectedItem.filter { $0.key.section == 0 }).values)
        let color = filteredColor.isEmpty ? nil : filteredColor
        
        let filteredBrand = Array((selectedItem.filter { $0.key.section == 1 }).values)
        let brand = filteredBrand.isEmpty ? nil : filteredBrand
        
        let filteredMaterial = Array((selectedItem.filter { $0.key.section == 2 }).values)
        let material = filteredMaterial.isEmpty ? nil : filteredMaterial
        
        let filteredSeason = Array((selectedItem.filter { $0.key.section == 3 }).values)
        let season = filteredSeason.isEmpty ? nil : filteredSeason
        
        if !isFixedPriceProducts {
            rangeSlider.isEnabled = true
            filterProducts = filterProductsUniversal(products: allProducts, color: color, brand: brand, material: material, season: season)
        } else {
            fixedPriceFilterProducts = filterProductsUniversal(products: allProducts, color: color, brand: brand, material: material, season: season, minPrice: Int(rangeSlider.lowerValue), maxPrice: Int(rangeSlider.upperValue))
        }

        // уходим от анимированного изменения цвета
        UIView.performWithoutAnimation {
               collectionView.reloadItems(at: [indexPath])
           }
    }
    
    

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
       
        var labelSize = CGSize()
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? MyCell
        
        switch indexPath.section {
        case 0:
            let colors = dataSource["color"]
            cell?.label.text = colors?[indexPath.row]
            //             Определяем размеры метки с помощью метода sizeThatFits()
            labelSize = cell?.label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)) ?? .zero
            labelSize = CGSize(width: labelSize.width + 20, height: labelSize.height + 20)
        case 1:
            let brands = dataSource["brand"]
            cell?.label.text = brands?[indexPath.row]
            labelSize = cell?.label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)) ?? .zero
            labelSize = CGSize(width: labelSize.width + 20, height: labelSize.height + 20)
        case 2:
            let material = dataSource["material"]
            cell?.label.text = material?[indexPath.row]
            labelSize = cell?.label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)) ?? .zero
            labelSize = CGSize(width: labelSize.width + 20, height: labelSize.height + 20)
        case 3:
            let season = dataSource["season"]
            cell?.label.text = season?[indexPath.row]
            labelSize = cell?.label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)) ?? .zero
            labelSize = CGSize(width: labelSize.width + 20, height: labelSize.height + 20)
        default:
            print("Returned message for analytic FB Crashlytics error")
            labelSize = .zero
        }
        return labelSize
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderFilterCollectionReusableView.headerIdentifier, for: indexPath) as! HeaderFilterCollectionReusableView

            // Customize your header view here based on the section index
            switch indexPath.section {
            case 0:
                headerView.configureCell(title: "Color")
            case 1:
                headerView.configureCell(title: "Brand")
            case 2:
                headerView.configureCell(title: "Material")
            case 3:
                headerView.configureCell(title: "Season")
            default:
                break
            }

            return headerView
        }
        fatalError("Unexpected element kind")
    }
   
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let headerView = HeaderFilterCollectionReusableView()
        headerView.configureCell(title: "Test")
        let width = collectionView.bounds.width
        let height = headerView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)).height
        
        return CGSize(width: width, height: height)
    }
    
    deinit {
        print("deinit CustomRangeViewController")
    }
}

extension CustomRangeViewController: CustomTabBarViewDelegate {
    
    func customTabBarViewDidTapButton(_ tabBarView: CustomTabBarView) {
        
        switch stateReturnFilterProduct {
            
        case .nul:
            returnFilterProducts()
        case .reset:
            delegate?.didChangedFilterProducts(filterProducts: allProducts, isActiveScreenFilter: false, isFixedPriceProducts: false, minimumValue: nil, maximumValue: nil, lowerValue: nil, upperValue: nil, countFilterProduct: nil, selectedItem: nil)
        case .firstStart:
            break
        }

        self.dismiss(animated: true, completion: nil)
    }
    
    func returnFilterProducts() {
        if !isFixedPriceProducts {
            if filterProducts.count != allProducts.count {
                delegate?.didChangedFilterProducts(filterProducts: filterProducts, isActiveScreenFilter: true, isFixedPriceProducts: false, minimumValue: minimumValue, maximumValue: maximumValue, lowerValue: rangeView.lowerValue, upperValue: rangeView.upperValue, countFilterProduct: filterProducts.count, selectedItem: selectedItem)
            } else {
                delegate?.didChangedFilterProducts(filterProducts: filterProducts, isActiveScreenFilter: false, isFixedPriceProducts: false, minimumValue: nil, maximumValue: nil, lowerValue: nil, upperValue: nil, countFilterProduct: nil, selectedItem: nil)
            }
        } else {
            if fixedPriceFilterProducts.count != allProducts.count {
                print("fixedPriceFilterProducts - \(fixedPriceFilterProducts)")
                delegate?.didChangedFilterProducts(filterProducts: fixedPriceFilterProducts, isActiveScreenFilter: true, isFixedPriceProducts: true, minimumValue: minimumValue, maximumValue: maximumValue, lowerValue: lowerValue, upperValue: upperValue, countFilterProduct: fixedPriceFilterProducts.count, selectedItem: selectedItem)
            } else {
                delegate?.didChangedFilterProducts(filterProducts: fixedPriceFilterProducts, isActiveScreenFilter: false, isFixedPriceProducts: true, minimumValue: nil, maximumValue: nil, lowerValue: nil, upperValue: nil, countFilterProduct: nil, selectedItem: nil)
            }
        }
    }
}

extension UIViewController {

    /// configure navigationBar and combines status bar with navigationBar
    func configureNavigationBar(largeTitleColor: UIColor, backgoundColor: UIColor, tintColor: UIColor, title: String, preferredLargeTitle: Bool) {
    if #available(iOS 13.0, *) {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: largeTitleColor]
        navBarAppearance.titleTextAttributes = [.foregroundColor: largeTitleColor]
        navBarAppearance.backgroundColor = backgoundColor
        navBarAppearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.compactAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance

        navigationController?.navigationBar.prefersLargeTitles = preferredLargeTitle
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.tintColor = tintColor
        navigationItem.title = title

    } else {
        // Fallback on earlier versions
        navigationController?.navigationBar.barTintColor = backgoundColor
        navigationController?.navigationBar.tintColor = tintColor
        navigationController?.navigationBar.isTranslucent = false
//        navigationController?.navigationBar.layer.shadowColor = nil
        navigationItem.title = title
    }
}}



class MyCell: UICollectionViewCell {

    let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textAlignment = .center
        label.textColor = UIColor.label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Добавление метки на ячейку и установка ограничений для ее размера
        contentView.backgroundColor = UIColor.secondarySystemBackground
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,constant: 0),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        ])
//        contentView.layer.borderWidth = 1
//        contentView.layer.borderColor = UIColor.label.cgColor
        contentView.layer.cornerRadius = 5
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class UserProfileTagsFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributesForElementsInRect = super.layoutAttributesForElements(in: rect) else { return nil }
        guard var newAttributesForElementsInRect = NSArray(array: attributesForElementsInRect, copyItems: true) as? [UICollectionViewLayoutAttributes] else { return nil }

        var leftMargin: CGFloat = 0.0;

        for attributes in attributesForElementsInRect {
            if (attributes.frame.origin.x == self.sectionInset.left) {
                leftMargin = self.sectionInset.left
            }
            else {
                var newLeftAlignedFrame = attributes.frame
                newLeftAlignedFrame.origin.x = leftMargin
                attributes.frame = newLeftAlignedFrame
            }
            leftMargin += attributes.frame.size.width + 8 // Makes the space between cells
            newAttributesForElementsInRect.append(attributes)
        }

        return newAttributesForElementsInRect
    }
}



protocol HeaderFilterCollectionViewDelegate: AnyObject {
    func didSelectSegmentControl()
}

class HeaderFilterCollectionReusableView: UICollectionReusableView {
    
    static let headerIdentifier = "HeaderFilterVC"
    weak var delegate: HeaderFilterCollectionViewDelegate?

    let label:UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.backgroundColor = .clear
//        label.tintColor = .black
        label.textColor = UIColor.label
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
//        addSubview(separatorView)
        setupConstraints()
        backgroundColor = .clear
    }
   
    private func setupConstraints() {
        NSLayoutConstraint.activate([label.topAnchor.constraint(equalTo: topAnchor, constant: 5), label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5), label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10), label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)])
    }
    
    func configureCell(title: String) {
        label.text = title
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(label)
        setupConstraints()
        backgroundColor = .clear
//        fatalError("init(coder:) has not been implemented")
    }
}

class CustomTabBarView: UIView {
    
    weak var delegate: CustomTabBarViewDelegate?
    
//    var countProducts:Int?
    let button: UIButton = {
        var configButton = UIButton.Configuration.gray()
        configButton.title = "Show products"
        configButton.baseForegroundColor = UIColor.label
        configButton.buttonSize = .large
        configButton.baseBackgroundColor = UIColor.systemPurple
        configButton.titleAlignment = .leading
        configButton.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incomig in

            var outgoing = incomig
            outgoing.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            return outgoing
        }
        var button = UIButton(configuration: configButton)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.secondarySystemBackground
        setupButton()
        button.addTarget(self, action: #selector(didTapDoneButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupButton()
    }

    private func setupButton() {
        addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            button.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            // Установим отступ до зоны жестов
            button.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }
    
    func setCounterButton(count:Int) {
        button.configuration?.title = "Show products(\(count))"
        if count <= 0 {
            button.isEnabled = false
        } else {
            button.isEnabled = true
        }
    }
    
    @objc func didTapDoneButton() {
        delegate?.customTabBarViewDidTapButton(self)
//        print("didTapDoneButton")
    }
}


class RangeView: UIView {
    
    let fromLabel: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.label
        view.textAlignment = .center
        return view
    }()
    
    let toLabel: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.label
        view.textAlignment = .center
        return view
    }()

    let titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.label
//        view.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        view.textAlignment = .left
        return view
    }()
    
    var lowerValue:Double?
    var upperValue:Double?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupUI()
    }
    
    private func setupUI() {
        
        // UILabel сверху на всю ширину
        titleLabel.frame = CGRect(x: 10, y: 0, width: frame.width - 20, height: 30)
        titleLabel.text = "Price range"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        addSubview(titleLabel)

        // Левый UILabel в одном ряду со сверху лежащим UILabel
        fromLabel.frame = CGRect(x: 10, y: titleLabel.frame.maxY + 10, width: 60, height: 30)
//        fromLabel.text = "238"
        fromLabel.backgroundColor = UIColor.secondarySystemBackground
        fromLabel.layer.cornerRadius = 5
        fromLabel.clipsToBounds = true
        addSubview(fromLabel)

        // Правый UILabel в одном ряду со сверху лежащим UILabel и прижатый к правому краю
        toLabel.frame = CGRect(x: frame.width - 70, y: titleLabel.frame.maxY + 10, width: 60, height: 30)
//        toLabel.text = "765"
        toLabel.backgroundColor = UIColor.secondarySystemBackground
        toLabel.layer.cornerRadius = 5
        toLabel.clipsToBounds = true
        addSubview(toLabel)
    }

    
    func updateLabels(lowerValue:Double, upperValue:Double) {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//
//      let minimumValueString = formatter.string(from: NSNumber(value: lowerValue))
//      let maximumValueString = formatter.string(from: NSNumber(value: upperValue))

//      fromLabel.text = "From \(minimumValueString ?? "")"
//      toLabel.text = "To \(maximumValueString ?? "")"
        fromLabel.text = "\(Int(lowerValue))"
        toLabel.text = "\(Int(upperValue))"
        self.lowerValue = lowerValue
        self.upperValue = upperValue
        
    }
    

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
}

//            if let minimumValue = minimumValue, let maximumValue = maximumValue, let lowerValue = lowerValue, let upperValue = upperValue  {
//                if lowerValue != upperValue {
//                    configureRangeViewForScreenFilter(minimumValue: minimumValue, maximumValue: maximumValue, lowerValue: lowerValue, upperValue: upperValue)
//                } else {
//                    configureRangeViewForScreenFilter(minimumValue: minimumValue, maximumValue: maximumValue, lowerValue: minimumValue, upperValue: maximumValue)
//                    isForcedPrice = true
//                    rangeSlider.isEnabled = false
//                    rangeView.updateLabels(lowerValue: lowerValue, upperValue: upperValue)
//                }
//
//            }

//        if let _ = firstCountProducts {
//            // если not nil то это хорошо работает для первого посещения с VC но
//            delegate?.didChangedFilterProducts(filterProducts: allProducts, isActiveScreenFilter: false, isFixedPriceProducts: false, minimumValue: nil, maximumValue: nil, lowerValue: nil, upperValue: nil, countFilterProduct: nil, selectedStates: nil, selectedCell: nil)
//        } else {
//            if !isFixedPriceProducts {
//                if filterProducts.count != allProducts.count {
//                    delegate?.didChangedFilterProducts(filterProducts: filterProducts, isActiveScreenFilter: true, isFixedPriceProducts: false, minimumValue: minimumValue, maximumValue: maximumValue, lowerValue: rangeView.lowerValue, upperValue: rangeView.upperValue, countFilterProduct: filterProducts.count, selectedStates: selectedStates, selectedCell: selectedCell)
//                } else {
//                    delegate?.didChangedFilterProducts(filterProducts: filterProducts, isActiveScreenFilter: false, isFixedPriceProducts: false, minimumValue: nil, maximumValue: nil, lowerValue: nil, upperValue: nil, countFilterProduct: nil, selectedStates: nil, selectedCell: nil)
//                }
//            } else {
//                if fixedPriceFilterProducts.count != allProducts.count {
//                    print("fixedPriceFilterProducts - \(fixedPriceFilterProducts)")
//                    delegate?.didChangedFilterProducts(filterProducts: fixedPriceFilterProducts, isActiveScreenFilter: true, isFixedPriceProducts: true, minimumValue: minimumValue, maximumValue: maximumValue, lowerValue: lowerValue, upperValue: upperValue, countFilterProduct: fixedPriceFilterProducts.count, selectedStates: selectedStates, selectedCell: selectedCell)
//                } else {
//                    delegate?.didChangedFilterProducts(filterProducts: fixedPriceFilterProducts, isActiveScreenFilter: false, isFixedPriceProducts: true, minimumValue: nil, maximumValue: nil, lowerValue: nil, upperValue: nil, countFilterProduct: nil, selectedStates: nil, selectedCell: nil)
//                }
//            }
//        }

//    private func calculatePriceRange(products: [Product]) {
//        var minPrice = Int.max
//        var maxPrice = Int.min
//
//        var counter = 0
//        for product in products {
//            counter+=1
//
//            if let price = product.price {
//
//                if price < minPrice {
//                    minPrice = price
//                }
//                if price > maxPrice {
//                    maxPrice = price
//                }
//            }
//        }
//
//        if counter == products.count {
//            print("minimumValue - \(minPrice)")
//            print("maximumValue - \(maxPrice)")
//            firstMinPrice = minPrice
//            firstMaxPrice = maxPrice
//        }
//    }

//    func filterProducts(products: [Product], color: String? = nil, brand: String? = nil, material: String? = nil, season: String? = nil) -> [Product] {
//        let filteredProducts = products.filter { product in
//            var isMatched = true
//
//            if let color = color {
//                isMatched = isMatched && product.color == color
//            }
//
//            if let brand = brand {
//                isMatched = isMatched && product.brand == brand
//            }
//
//            if let material = material {
//                isMatched = isMatched && product.material == material
//            }
//
//            if let season = season {
//                isMatched = isMatched && product.season == season
//            }
//
//            return isMatched
//        }
//
//        return filteredProducts
//    }

//    func filterProductsForBrands(products: [Product], brands: [String]? = nil) -> [Product] {
//        let filteredProducts = products.filter { product in
//            var isMatched = true
//
//            if let brands = brands {
//                isMatched = isMatched && brands.contains(product.brand ?? "")
//            }
//            return isMatched
//        }
//
//        return filteredProducts
//    }

//    func filterProducts(products: [Product], color: String? = nil, brand: String? = nil, material: String? = nil, season: String? = nil) -> [Product] {
//        let filteredProducts = products.filter { product in
//            var isMatched = true
//
//            if let color = color {
//                isMatched = isMatched && product.color == color
//            }
//
//            if let brand = brand {
//                isMatched = isMatched && product.brand == brand
//            }
//
//            if let material = material {
//                isMatched = isMatched && product.material == material
//            }
//
//            if let season = season {
//                isMatched = isMatched && product.season == season
//            }
//
//            return isMatched
//        }
//
//        return filteredProducts
//    }


//        filterAllProduct(products: allProducts) { [weak self] (dataSource, min, max) in
//
//            configureRangeView(minimumValue: Double(min), maximumValue: Double(max))
//            self?.dataSource = dataSource
//        }
//    func filterAllProduct(products: [Product], completion: ([String: [String]], Int, Int ) -> Void
//    ) {
//        var minPrice = Int.max
//        var maxPrice = Int.min
//        var dataSource = [String: [String]]()
//        var counter = 0
//        for product in products {
//            counter+=1
//            if let color = product.color {
//                dataSource["color", default: []].append(color)
//            }
//            if let brand = product.brand {
//                dataSource["brand", default: []].append(brand)
//            }
//            if let material = product.material {
//                dataSource["material", default: []].append(material)
//            }
//            if let season = product.season {
//                dataSource["season", default: []].append(season)
//            }
//            if let price = product.price {
//
//                   if price < minPrice {
//                       minPrice = price
//                   }
//                   if price > maxPrice {
//                       maxPrice = price
//                   }
//               }
//        }
//        if counter == products.count {
//            for key in dataSource.keys {
//                let values = Set(dataSource[key]!)
//                dataSource[key] = Array(values)
//                let sortValue = dataSource[key]?.sorted()
//                dataSource[key] = sortValue
//            }
//            completion(dataSource,minPrice, maxPrice)
//        }
//
//    }
//        var minPrice = Int.min
//        var maxPrice = Int.max
//        var dataSource = [String: [String]]()
//        print("calculateDataSource - allProducts = \(allProducts)")
//        for product in allProducts {
//            if let color = product.color {
//                dataSource["color", default: []].append(color)
//            }
//            if let brand = product.brand {
//                dataSource["brand", default: []].append(brand)
//            }
//            if let material = product.material {
//                dataSource["material", default: []].append(material)
//            }
//            if let season = product.season {
//                dataSource["season", default: []].append(season)
//            }
//            if let price = product.price {
//
//                   if price < minPrice {
//                       print("Price - \(price)")
//                       print("minPrice До - \(minPrice)")
//                       minPrice = price
//                       print("minPrice - \(minPrice)")
//                   }
//                   if price > maxPrice {
//                       maxPrice = price
//                   }
//               }
//        }
//            print("min max - \(min)")
//            var dataSourceType = [String: [String]]()
//            // Удаление повторяющихся значений из каждой категории
//            for key in dataSource.keys {
//                let values = Set(dataSource[key]!)
//                dataSourceType[key] = Array(values)
//            }
//
//            for key in dataSourceType.keys {
//                if var values = dataSourceType[key] {
//                    values.sort()
//                    dataSourceType[key] = values
//                }
//            }
//            print("calculateDataSource() - \(min)")
//            for key in dataSource.keys {
//                if var values = dataSource[key] {
//                    values.sort()
//                    dataSource[key] = values
//                }
//            }
