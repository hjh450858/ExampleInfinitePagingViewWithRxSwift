//
//  ViewController.swift
//  ExampleInfinitePagingScroll
//
//  Created by 황재현 on 3/4/24.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then


class ViewController: UIViewController {
    
    /// 테이블뷰
    let tableView = UITableView().then {
        $0.register(ItemCell.self, forCellReuseIdentifier: "ItemCell")
    }
    
    /// 아이템 데이터
    var dataSource = BehaviorRelay<[Int]>(value: Array(0...50))
    
    let disposeBag = DisposeBag()
    
    /// 페이징 로딩 진행여부 값
    var isLoading: Bool = false
    
    /// 인디케이터 로딩여부 이벤트값
    var isIndicatorView = BehaviorRelay<Bool>(value: false)
    /// 로딩여부 이벤트값
    var isLoadingEvent = BehaviorRelay<Bool>(value: false)
    
    /// 로딩창
    var indicatorView = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        
        bindingVM()
    }

    
    func configureUI() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view)
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        view.addSubview(indicatorView)
        
        indicatorView.snp.makeConstraints { make in
            make.center.equalTo(view.center)
        }
        
    }
    
    func bindingVM() {
        self.dataSource
            .catchAndReturn([404, 404, 404, 404])
            .observe(on: MainScheduler.instance)
            .bind(to: tableView.rx.items(cellIdentifier: "ItemCell", cellType: ItemCell.self)) { (index, element, cell) in
                cell.textLabel?.text = "\(element)"
            }.disposed(by: disposeBag)
        
        // contentOffset 구독 (scrollViewDidScroll 대행)
        self.tableView.rx.contentOffset.subscribe { [weak self] result in
            guard let self = self else { return }
            guard let wrappingValue = result.element?.y else { return }
            
            // TODO: - wrappigValue값이 tableView.y값보다 높으면 데이터 추가?
            
            // 페이지 로딩 중복 방지
            if isLoading {
                return
            }
            
            if wrappingValue > (self.tableView.contentSize.height - tableView.frame.size.height) {
                print("paging")
                // 데이터 로딩
                self.isLoadingEvent.accept(true)
                
                // 데이터 추가
                self.addData()
            }
        }.disposed(by: disposeBag)
        
        // 인디케이터뷰 액션 이벤트
        self.isIndicatorView.subscribe(onNext: { [weak self] flag in
            guard let self = self else { return }
            print("isIndicatorView - flag = \(flag)")
            flag ? self.indicatorView.startAnimating() : self.indicatorView.stopAnimating()
        }).disposed(by: disposeBag)
        
        // 로딩여부 이벤트
        self.isLoadingEvent.subscribe(onNext: { [weak self] flag in
            guard let self = self else { return }
            print("isLoadingEvent - flag = \(flag)")
            self.isLoading = flag
            
        }).disposed(by: disposeBag)
    }
    
    
    
    /// 데이터 추가
    func addData() {
        self.isIndicatorView.accept(true)
        
        // 마지막 값 출력
        guard let lastElement = self.dataSource.value.last else { return }
        print("lastElement = \(lastElement)")
        
        let newData = [lastElement + 1]
        // 데이터 추가
        self.dataSource.accept(self.dataSource.value + newData)
        
        self.isIndicatorView.accept(false)
        self.isLoadingEvent.accept(false)
    }
}
