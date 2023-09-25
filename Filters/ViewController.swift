//
//  ViewController.swift
//  Filters
//
//  Created by Evgenyi on 14.09.23.
//
// лдодло
// first commit remote repository
import UIKit

protocol CustomRangeViewDelegate: AnyObject {
    func didTapDone(filterProducts:[Product])
}
class ListViewController: UIViewController {
    
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
        reserverDataSource = dataSource
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
        print("filterButtonTapped()")
        let customVC = CustomRangeViewController()
        customVC.allProducts = reserverDataSource
        customVC.delegate = self
        let navigationVC = CustomNavigationController(rootViewController: customVC)
        navigationVC.navigationBar.backgroundColor = UIColor.secondarySystemBackground
        navigationVC.modalPresentationStyle = .fullScreen
        present(navigationVC, animated: true, completion: nil)
    }

    @objc func sortedButtonTapped() {
        print("sortedButtonTapped()")
        // Обработчик нажатия на кнопку "sorted"
    }

}

extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let separator = " "
        let combinedStringWithSeparator = [String("\(dataSource[indexPath.row].price!)"), dataSource[indexPath.row].material ?? "", dataSource[indexPath.row].season ?? "", dataSource[indexPath.row].color ?? ""].joined(separator: separator)

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
    func didTapDone(filterProducts: [Product]) {
        dataSource = filterProducts
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

    init(color: String?, brand: String?, material: String?, season: String?, price: Int?) {
        self.color = color
        self.brand = brand
        self.material = material
        self.season = season
        self.price = price
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

            let product = Product(color: color[randomColorIndex],
                                  brand: brand[randomBrandIndex],
                                  material: material[randomMaterialIndex],
                                  season: season[randomSeasonIndex],
                                  price: randomPrice)

            products.append(product)
        }
        print("createRandomProduct products.count - \(products.count)")
        return products
    }

}


