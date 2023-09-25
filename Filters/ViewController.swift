//
//  ViewController.swift
//  Filters
//
//  Created by Evgenyi on 14.09.23.
//
// лдодло
// first commit remote repository
import UIKit

enum AlertActions:String {
    case Recommendation
    case PriceDown
    case PriceUp
    case Alphabetically
}

protocol CustomRangeViewDelegate: AnyObject {
    func didChangedFilterProducts(filterProducts:[Product])
}

class ListViewController: UIViewController {
    
    var alert:UIAlertController?
    var changedAlertAction:AlertActions = .Recommendation
    
    var reserverDataSource: [Product] = []
    var dataSource: [Product] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    var dataManager = FactoryProducts.shared
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        setupConstraints()
        configureNavigationItem()
        dataSource = dataManager.createRandomProduct()
        sortRecommendation()
        reserverDataSource = dataSource
        setupAlertSorted()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0), tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0), tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0), tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)])
    }
    
    private func configureNavigationItem() {
        
        // Создание кнопок
        let filterButton = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3.decrease"), style: .plain, target: self, action: #selector(filterButtonTapped))
        let sortedButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(sortedButtonTapped))
        navigationItem.rightBarButtonItems = [sortedButton, filterButton]
    }
    
    @objc func filterButtonTapped() {
        let customVC = CustomRangeViewController()
        customVC.allProducts = reserverDataSource
        customVC.delegate = self
        let navigationVC = CustomNavigationController(rootViewController: customVC)
        navigationVC.navigationBar.backgroundColor = UIColor.secondarySystemBackground
        navigationVC.modalPresentationStyle = .fullScreen
        present(navigationVC, animated: true, completion: nil)
    }

    @objc func sortedButtonTapped() {
        
        if let alert = alert {
            alert.actions.forEach { action in
                if action.title == changedAlertAction.rawValue {
                    action.setValue(UIColor.systemGray3, forKey: "titleTextColor")
                    action.isEnabled = false
                } else {
                    action.isEnabled = true
                    action.setValue(UIColor.systemPurple, forKey: "titleTextColor")
                }
                
            }
            present(alert, animated: true, completion: nil)
        }
    }
}

extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let separator = " "
        let combinedStringWithSeparator = [String("\(dataSource[indexPath.row].price!)"), dataSource[indexPath.row].material ?? "", dataSource[indexPath.row].season ?? "", dataSource[indexPath.row].color ?? "", String("\(dataSource[indexPath.row].sortIndex ?? 0)") ].joined(separator: separator)

        var contentCell = cell.defaultContentConfiguration()
        
        contentCell.text = dataSource[indexPath.row].brand
        contentCell.secondaryText = combinedStringWithSeparator
        contentCell.image = UIImage(systemName: "swift")
        contentCell.textProperties.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        contentCell.imageProperties.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .callout)
        contentCell.imageToTextPadding = 8
        cell.contentConfiguration = contentCell
        return cell
    }
}

extension ListViewController:CustomRangeViewDelegate {
    func didChangedFilterProducts(filterProducts: [Product]) {
        
        dataSource = filterProducts
        
        switch changedAlertAction {
        case .Recommendation:
            sortRecommendation()
        case .PriceDown:
            sortPriceDown()
        case .PriceUp:
            sortPriceUp()
        case .Alphabetically:
            sortAlphabetically()
        }
    }
}

extension ListViewController {
    
    
    func setupAlertSorted() {

        alert = UIAlertController(title: "", message: nil, preferredStyle: .actionSheet)
        alert?.overrideUserInterfaceStyle = .dark
        
        
        let recommendation = UIAlertAction(title: "Recommendation", style: .default) { action in
            self.changedAlertAction = .Recommendation
            self.sortRecommendation()
            print("recommendation")

        }
        
        let priceDown = UIAlertAction(title: "PriceDown", style: .default) { action in
            self.changedAlertAction = .PriceDown
            self.sortPriceDown()
            print("Price:Down")

        }

        let priceUp = UIAlertAction(title: "PriceUp", style: .default) { action in
            self.changedAlertAction = .PriceUp
            self.sortPriceUp()
            print("Price:Up")

        }
        
        let alphabetically = UIAlertAction(title: "Alphabetically", style: .default) { action in
            self.changedAlertAction = .Alphabetically
            self.sortAlphabetically()
            print("Alphabetically")
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
            
        }

        let titleAlertController = NSAttributedString(string: "Add image to avatar", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)])
        alert?.setValue(titleAlertController, forKey: "attributedTitle")

        
        alert?.addAction(recommendation)
        alert?.addAction(priceDown)
        alert?.addAction(priceUp)
        alert?.addAction(alphabetically)
        alert?.addAction(cancel)
    }
    
    func sortAlphabetically() {
        dataSource.sort { (product1, product2) -> Bool in
            guard let brand1 = product1.brand, let brand2 = product2.brand else {
                return false // Обработайте случаи, когда brand равно nil, если это необходимо
            }
            return brand1.localizedCaseInsensitiveCompare(brand2) == .orderedAscending
        }
    }
    
    func sortPriceDown() {
        dataSource.sort { (product1, product2) -> Bool in
            guard let price1 = product1.price, let price2 = product2.price else {
                return false // Обработайте случаи, когда price равно nil, если это необходимо
            }
            return price1 > price2
        }
    }
    
    func sortPriceUp() {
        dataSource.sort { (product1, product2) -> Bool in
            guard let price1 = product1.price, let price2 = product2.price else {
                return false // Обработайте случаи, когда price равно nil, если это необходимо
            }
            return price1 < price2
        }
    }
    
    func sortRecommendation() {
        dataSource.sort { (product1, product2) -> Bool in
            guard let price1 = product1.sortIndex, let price2 = product2.sortIndex else {
                return false // Обработайте случаи, когда price равно nil, если это необходимо
            }
            return price1 > price2
        }
    }
    
    
}



class ViewController: UIViewController {

    var dataSource = [String:[String]]()
    let customRangeButton: UIButton = {
        var configuration = UIButton.Configuration.gray()
       
        configuration.titleAlignment = .center
        configuration.buttonSize = .large
        configuration.baseBackgroundColor = .systemPink
        
        var container = AttributeContainer()
        container.font = UIFont.boldSystemFont(ofSize: 15)
        container.foregroundColor = .black
        configuration.attributedTitle = AttributedString("CustomRangeVC", attributes: container)
        
        var grayButton = UIButton(configuration: configuration)
        grayButton.translatesAutoresizingMaskIntoConstraints = false
        grayButton.addTarget(self, action: #selector(addCustomRangeButton(_:)), for: .touchUpInside)
        
        return grayButton
    }()
    
    var dataManager = FactoryProducts.shared
    
    let dependencyRangeButton: UIButton = {
        
        var configuration = UIButton.Configuration.gray()
       
        configuration.titleAlignment = .center
        configuration.buttonSize = .large
        configuration.baseBackgroundColor = .systemPink
        
        var container = AttributeContainer()
        container.font = UIFont.boldSystemFont(ofSize: 15)
        container.foregroundColor = .black
        configuration.attributedTitle = AttributedString("DependencyRangeVC", attributes: container)
        
        var grayButton = UIButton(configuration: configuration)
        grayButton.translatesAutoresizingMaskIntoConstraints = false
        grayButton.addTarget(self, action: #selector(addDependencyRangeButton(_:)), for: .touchUpInside)
        
        return grayButton
    }()
    
    let stackViewForButton: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fill
        stack.spacing = 5
        return stack
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGray6
        
        stackViewForButton.addArrangedSubview(customRangeButton)
        stackViewForButton.addArrangedSubview(dependencyRangeButton)
        view.addSubview(stackViewForButton)
        
        NSLayoutConstraint.activate([stackViewForButton.centerXAnchor.constraint(equalTo: view.centerXAnchor), stackViewForButton.centerYAnchor.constraint(equalTo: view.centerYAnchor), stackViewForButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), stackViewForButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)])
        
    }

    @objc func addCustomRangeButton(_ sender: UIButton) {
        
//        let color = ["Red", "Blue", "Green", "Black", "White", "Purpure", "Yellow", "Pink"]
//        let brand = ["Nike", "Adidas", "Puma", "Reebok", "QuikSilver", "Boss", "LCWKK", "Marko", "BMW", "Copertiller"]
//        let material = ["leather", "artificial material"]
//        let season = ["summer", "winter", "demi-season"]
//        dataSource["colors"] = color
//        dataSource["brands"] = brand
//        dataSource["material"] = material
//        dataSource["season"] = season
        let customVC = CustomRangeViewController()
        customVC.allProducts = dataManager.createRandomProduct()
        let navigationVC = CustomNavigationController(rootViewController: customVC)
        navigationVC.navigationBar.backgroundColor = UIColor.secondarySystemBackground
        navigationVC.modalPresentationStyle = .fullScreen
        present(navigationVC, animated: true, completion: nil)
    }
    
    @objc func addDependencyRangeButton(_ sender: UIButton) {
        
    }
}

class CustomNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
}

class Product {
    var color: String?
    var brand: String?
    var material: String?
    var season: String?
    var price: Int?
    var sortIndex:Int?

    init(color: String?, brand: String?, material: String?, season: String?, price: Int?, sortIndex:Int?) {
        self.color = color
        self.brand = brand
        self.material = material
        self.season = season
        self.price = price
        self.sortIndex = sortIndex
    }
}

class FactoryProducts {
    
    static let shared = FactoryProducts()
    let color = ["Dark", "Bright"]
    let brand = ["Nike", "Adidas", "Puma", "Reebok", "QuikSilver", "Boss", "LCWKK", "Marko", "Copertiller"]
    let material = ["Leather", "Artificial Material"]
    let season = ["Summer", "Winter", "Demi-Season"]
    

    var products = [Product]()

    func createRandomProduct() -> [Product] {
        products = []
        for _ in 1...20 {
            let randomBrandIndex = Int.random(in: 0..<brand.count)
            let randomColorIndex = Int.random(in: 0..<color.count)
            let randomMaterialIndex = Int.random(in: 0..<material.count)
            let randomSeasonIndex = Int.random(in: 0..<season.count)
            let randomPrice = Int.random(in: 0...999)
            let sortIndex = Int.random(in: 0...5)

            let product = Product(color: color[randomColorIndex],
                                  brand: brand[randomBrandIndex],
                                  material: material[randomMaterialIndex],
                                  season: season[randomSeasonIndex],
                                  price: randomPrice, sortIndex: sortIndex)

            products.append(product)
        }
        print("createRandomProduct products.count - \(products.count)")
        return products
    }

}


