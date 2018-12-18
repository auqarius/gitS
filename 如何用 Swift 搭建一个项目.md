# 用 Swfit 搭建一个完整项目

Swift 目前更新到了 Swift4，已经相当稳定，相比于之前的版本跳跃就得重学的情况，从  Swift3 更新到 Swift4 的成本非常小。

再加上苹果极力推行 Swift，可以预见在不远的未来，Objective-C 将会被淘汰，现在可见最多的就是混编，OC 项目添加 Swift 代码，将老项目一步步更改为 Swift 版本，这样也是学习和研究 Swift 的一种方法。但这种方式，我们的基础代码和架构依然是 OC，那么怎样使用 Swift 搭建一个项目并完全使用 Swift 就是一个需要解决的问题。

这里要讨论的，就是如何用 Swift 搭建一个项目。首先表明这里只是针对单个项目，对于组件化等开发模式来说，会更加复杂，但是基础还是可以通用的。

对于一个 iOS 项目，在搭建项目的时候，使用的架构为 MVVM 架构，需要考虑的有以下几点：

1. [数据模型](#model)
2. [网络请求](#API)
3. [缓存](#Cache)
4. [代码架构 - MVVM](#mvvm)
5. [图片加载](#imageload)
6. [工具类](#Tools)
7. [单元测试](#UnitTest)
8. [安全](#Safe)

在考虑的时候，优先根据 MVVM 考虑各个模块的分工，这里把 MVVM 放到了第四位，只是因为在实现 viewModel 和 view 的时候，需要前面的支持。

### RxSwift

在介绍之前，先说一下  [RxSwift](https://github.com/ReactiveX/RxSwift)，[ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) 这个之前应该很多人使用，但凡说是要做 MVVM 架构，都会加入 ReactiveCocoa，而 Swift 版的就叫做 RxSwift。想要深入学习的，可以搜索一下，相关文章很多，这里就不做解释。

在本次的项目中，RxSwift 会非常频繁的被使用，在以上所列出来的模块中，基本每个模块都有涉及到。

## <a name="model"></a>1. 数据模型

数据是程序运行的基础，也对应了 MVVM 架构中的 Model ，它负责整个数据的构建及内部数据处理。

从使用数量上来说，Json 依然是数据传输的普遍格式，[protobuf](https://github.com/google/protobuf) 是 Google 推出的一个数据交换格式，它更小，更迅速，也更加安全，这在未来是趋势，但现在还是 Json 更普遍。 

在这里，使用的是 [HandyJSON](https://github.com/alibaba/HandyJSON) 来进行数据解析，其优势是可以自动进行解析，代码简单，还会进行自动类型转换，这样即使约定好的数据类型发生变化，也不会影响到程序的正常运行。

一般服务器传来的数据都会进行格式化，最外层的结构都是一样的，例如：

```
{
	"code": 200,
	"msg": "success",
	"datas": {
		// 对应的数据
	}
}
```

所有的数据返回，都会是以这样的结构传递回来，不同的是 datas 的内容。按照这样的思路，我们可以做一个基类叫做 Base，它的责任就是负责解析这些通用的数据。对于这个 code，200 是成功，其他的值就是失败，详细点的话，会有各种不同的对应，就像 http 的状态码一样，因此这个 code 可以做成一个枚举。代码如下：

```
/// 服务器规定，接口调用成功为 200，其他数字则为失败
///
/// - success: 请求成功
/// - fail: 未定义的请求失败
/// - logout: 强制登出
enum ResponseCode: Int, HandyJSONEnum {
    case success = 200 
    case fail = -1
    case logout = 10504
}

/// response 最外层的数据，内层模型不需要继承 base
class Base: HandyJSON {
    
    // 未定义的 code 有千万种，因此默认请求的结果是未定义错误
    var code: ResponseCode = .fail
    var message: String = "Resquest something error"
    
    required init() {}
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            [
                self.code       <-- "code",
                self.message    <-- "msg",
            ]
        
    }
}

```
这样，我们一个基础的模型就做好了，后面所有符合这个规则的模型，都会继承这个类，然后实现自己的 datas 转意。例如一个用户返回类：

```
// 返回里有 Base 中的字段：code、msg，因此 response 继承自 Base
class UserResponse: Base {
    
    var user: User?
    
    override func mapping(mapper: HelpingMapper) {
        super.mapping(mapper: mapper)
        
        mapper <<<
            self.user <-- "prData"
    }

}

// 而作为我们真正使用的 User 类，它是没有 Base 的数据的，所以不用继承
class User: HandyJSON {
    
    var email: String?
    
    var userName: String?
        
    var userToken: String?
    
    required init() { }
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            [
                self.email              <-- "mail",
                self.userName           <-- "userName",
                self.userToken          <-- "utoken"
        ]
    }
    
}
```
在做数据模型的时候，一定不要在其他地方做任何解析 Json 的行为，见过有很多人在 ViewModel 里面请求到数据后进行数据解析，将 code 那一层使用 NSDictionary 来通过键值来取，判定完状态后，再将 datas 里面的内容解析成数据模型。这样的问题就是会有很多冗余代码，在写代码的时候会非常痛苦，后期维护也会非常困难。最重要的是，这完全不符合 MVVM 或 MVC 的设计模式。

在 Model 的内部数据处理中，我们可以将一些转换操作和对应类的某些操作放在模型中，比如我们要给用户添加一个创建日期的字段，服务端传来的数据一般是时间戳：

```
"craete_date": 4383920100
```
写转换的时候，可以将时间戳转换为我们需要的 Date 类型这一过程放到 Model 中。

```
var create_date: Int64?

var createDate: Date? {
	get {
		guard let create_date = create_date else { return nil }
		
		// 将 create_date 转换为 Date
		let resultDate = Date(timeIntervalSince1970: create_date)
		
		return resultDate
	}
}
```

## <a name="API"></a>2. 网络请求

网络请求是项目中非常重要的模块，在这里我们使用 [Alamofire](https://github.com/Alamofire/Alamofire) 进行网络请求，一般将这个类命名为 API。在这里，我们使用了 Alamofire + RxSwift + HandyJSON 组合的方式，将数据请求到数据解析这一过程整合在一起。

### 2.1 错误类型

在正式介绍之前，先说一下错误类型，在  Swift 中是没有错误类的，有一个 Error 的协议，我们所有的错误要遵循这个协议来进行开发，当然 NSError 还是可以使用的，但非必须的时候不建议使用 OC 的类。我们先定义一个 APIError 的类，它囊括了在 API 请求的过程中可能出现的所有错误类型：

```
enum APIError: Error {
    /*
     请求出错，服务器会返回对应的描述文字
     */
    case error(wrong: String)
    /*
     服务器返回的数据不是 JSON
     */
    case dataJSON(wrong: String)
    /*
     服务器返回的数据为空
     */
    case dataEmpty(wrong: String)
    /*
     服务器返回的数据不能解析
     */
    case datamatch(wrong: String)
    /*
     网络请求错误
     */
    case network(wrong: String)
    
    /*
     使用 NSError 创建网络请求错误
     */
    static func networkWrong(with error: NSError) -> APIError {
        if let errorMessage = error.userInfo["NSLocalizedDescription"] as? String {
            return APIError.network(wrong: errorMessage)
        }
        
        if error.domain == "Alamofire.AFError" {
            // 处理 Alamofire 返回的错误
            if error.code == 4 {
                return APIError.dataEmpty(wrong: "Server return data is nil or zero length.")
            }
        }
        
        return APIError.network(wrong: "Unknown Network Wrong.")
    }
}

// 这里写了一个 Extension 用来做错误的提示
// 注意这里会有重复代码，但是为了给错误做区分，还是使用了这种方式
// 这里可以考虑将 APIError 写成一个 Class，然后添加一个 ErrorType 的枚举，可能代码会少一点，但是在使用的时候其实还是一样的
// 当然，如果不考虑错误类型，那就不需要 ErrorType ，直接一个错误描述就可以。
extension APIError {
    func showHUD() {
        switch self {
        case .error(let wrong):
            HUD.showError(with: wrong)
            break
        case .dataEmpty(let wrong):
            HUD.showError(with: wrong)
            break
        case .dataJSON(let wrong):
            HUD.showError(with: wrong)
            break
        case .datamatch(let wrong):
            HUD.showError(with: wrong)
            break
        case .network(let wrong):
            HUD.showError(with: wrong)
            break
        }
    }
}

```
### 2.2 路径

每个请求都会有自己的路径，针对路径我们需要做一个类来专门进行维护，Alamofire 推荐的方法是写成一个 enum 并且遵循其 [URLConvertible 或 URLRequestConvertible  协议]((https://github.com/Alamofire/Alamofire#routing-requests))。在这里，我们使用了 URLConvertible 协议。

代码如下：

```
/// 请求路由
enum Router: String, URLConvertible {
    
    /// 登录
    case login = "Account/login"
    /// 注册
    case register = "Account/register"
    /// 其他
        
    /// 域名
    static var baseURL: String {
        get {
            if Cache.isTestEnvironment {
            	// 测试环境
                return "http://api.beta.xxxxx.com/Api/"
            } else {
            	// 正式环境
                return "https://api.xxxxx.com/Api/"
            }
        }
    }
    
    var appendURL: String {
        get {
            return rawValue
        }
    }
    
    func asURL() throws -> URL {
        let nowTimeInterval = Int64(NSDate().timeIntervalSince1970)
        let urlString = Router.baseURL.appending(appendURL) + "?t=\(nowTimeInterval)"
        
        return URL(string: urlString)!
    }
}
```
### 2.3 请求

对于 API 类，我们需要一个基础的方法来做所有的请求，并处理相关数据。首先我们需要设定请求头，一般情况下，我们所有的请求头内容都是固定的。经过讨论和 http2.0 的发展趋势来看，header 内部尽量减少内容，不要添加太多。以下为配置代码：

```
class API {
    static var headers: HTTPHeaders {
        get {
            
            let os = "iOS"
            let client = UIDevice.sysNameVersion // 获取系统的版本号，在工具类中
            
            let result: [String: String] = ["os": os, "client": client]
            
            return result
        }
    }
}

```

在具体实现中，为了在这一步就可以完成数据解析，我们使用一个 `<T: HandyJSON>` 和 `returnType: T.type` 来确定返回的数据类型，`<T: HandyJSON>` 决定了我们传过来的 `returnType` 必须是遵循 `HandyJSON` 协议的类型，然后使用 `returnType` 进行数据解析，就可以得到对应类型的数据，具体实现如下：

```
extension API  {
    
    /// 将 Alamofire、RxSwift、HandyJSON 结合
    ///
    /// 可以通过 RxSwift 的方式通过 Alamofire 获取到数据后使用 HandyJSON 将数据转换成需要的模型
    ///
    /// - Parameters:
    ///   - url: 访问路径
    ///   - method: 请求方式
    ///   - uploadData: 请求参数
    ///   - parameters: 上传数据
    ///   - returnType: 返回模型的类型
    /// - Returns: Observable<HandyJSON> onNext 说明请求正确，发送的数据就是需要的数据，onError 说明请求失败，会返回失败原因
    fileprivate class func request<T: HandyJSON>(_ url: Router, method: HTTPMethod = .post, uploadData: Data? = nil, parameters: Parameters?, returnType: T.Type) -> Observable<T> {
        return Observable.create({ observer in
            
            if let uploadData = uploadData {
                upload(observer: observer, url: url, method: method, uploadData: uploadData, parameters: parameters, returnType: returnType)
            } else {
                requestData(observer: observer, url: url, method: method, parameters: parameters, returnType: returnType)
            }
            
            return Disposables.create {}
        })
    }
    
    /// Post 请求
    ///
    /// - Parameters:
    ///   - observer: Rx 观察者， 用来向外部传递数据
    ///   - url: 请求链接
    ///   - method: 请求方式
    ///   - parameters: 请求参数
    ///   - returnType: 返回值类型
    fileprivate class func requestData<T: HandyJSON>(observer: AnyObserver<T>, url: Router, method: HTTPMethod = .post, parameters: Parameters?, returnType: T.Type) {
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler: { response in
            switch response.result {
            case .success:
                self.successHandle(observer: observer, result: response.result, returnType: returnType)
                break
            case .failure(let error):
                observer.onError(APIError.networkWrong(with: error as NSError))
                observer.onCompleted()
                break
            }
        })
    }
    
    /// 上传图片或其他信息
    ///
    /// - Parameters:
    ///   - observer: Rx 观察者，用来向外部传递数据
    ///   - url: 请求链接
    ///   - method: 请求方式
    ///   - uploadData: 上传数据
    ///   - parameters: 请求参数
    ///   - returnType: 返回值类型
    fileprivate class func upload<T: HandyJSON>(observer: AnyObserver<T>, url: Router, method: HTTPMethod = .post, uploadData: Data, parameters: Parameters?, returnType: T.Type) {
        Alamofire.upload(multipartFormData: { (data: MultipartFormData) in
            
            // Parameters
            if let parameters = parameters {
                for param in parameters {
                    let value = (param.value as! String).data(using: .utf8)
                    data.append(value!, withName: param.key)
                }
            }
            
            // uploadData
            data.append(uploadData, withName: "attachment", fileName: "attachment.jpg", mimeType: "image/jpg")
            
        },
             to: url,
             method: .post,
             headers: headers,
             encodingCompletion: { (result: SessionManager.MultipartFormDataEncodingResult) in
                switch result {
                case .success(let upload, _, _):
                    upload.responseJSON(completionHandler: { (response: DataResponse<Any>) in
                        self.successHandle(observer: observer, result: response.result, returnType: returnType)
                    })
                    break
    
                case .failure(let encodingError):
                    self.failHandle(observer: observer, error: encodingError)
                    break
            }
        })
    }
    
}

/// MARK: - Result Handler
///
/// 请求结果的处理，在这里只是第一步，首先确认的就是数据是否符合要求：
/// 1. 是否不为空
/// 2. 是否是 JSON
/// 3. 是否可以转化为我们自定义的 Model
///
///  而这个 Model 中的数据错误，将在另外一个方法中进行甄别
extension API {
    
    /// 请求成功的处理
    ///
    /// - Parameters:
    ///   - observer: Rx 观察者，给外部传递数据
    ///   - result: 请求结果
    ///   - returnType: 返回值的类型
    fileprivate class func successHandle<T: HandyJSON>(observer: AnyObserver<T>, result: Result<Any>, returnType: T.Type) {
        // 服务器返回数据残缺
        guard let JSON = result.value,
            let jsonDic = JSON as? Dictionary<String, AnyObject> else {
                observer.onError(APIError.dataJSON(wrong: "Server Data is not JSON!"))
                observer.onCompleted()
                return
        }
        
        // 
        guard let responseModel = returnType.deserialize(from: NSDictionary(dictionary: jsonDic)) else {
            // 数据解析错误
            observer.onError(APIError.datamatch(wrong: "Data match wrong!"))
            observer.onCompleted()
            return
        }
       
       // 数据解析成功
        observer.onNext(responseModel)
        observer.onCompleted()
    }
    
    /// 请求失败的处理
    ///
    /// - Parameters:
    ///   - observer: Rx 观察者 ，给外部传递数据
    ///   - error: 返回值的类型
    fileprivate class func failHandle<T: HandyJSON>(observer: AnyObserver<T>, error: Error) {
        observer.onError(APIError.networkWrong(with: error as NSError))
        observer.onCompleted()
    }
}
```
当数据模型获取成功后，还不能直接交给外部使用，需要做更近一步的数据筛选，在这一步中，`<T: Base>` 进行了修改，因为我们所有请求的返回都是格式化过的，而对于格式化过的数据，所有的 Model 都是继承 Base 的，这样可以进一步避免在调用这个方法的时候出现参数传递的错误，例如上面数据模型中的 UserResponse 和 User 类，这里需要的就是 UserResponse。

```
/// 获取数据，在这里将对解析成功的数据进行筛选，进一步将错误提取出来，保证外部使用的时候拿到的数据是可以直接使用的
    ///
    /// - Parameters:
    ///   - url: 请求链接
    ///   - method: 请求方式
    ///   - uploadData: 上传数据
    ///   - parameters: 请求参数
    ///   - returnType: 返回值类型
    /// - Returns: Observable<Base>
    class func fetchData<T: Base>(from url: Router, method: HTTPMethod = .post, uploadData: Data? = nil, parameters: Parameters?, returnType: T.Type) -> Observable<T> {
        
        return Observable<T>.create({ (observer: AnyObserver<T>) -> Disposable in
            
            let disposable = self.request(url, method: method, uploadData: uploadData, parameters: parameters, returnType: returnType).subscribe(onNext: { (data: T) in
                
                // 将要在这里处理一些类似登出的统一接口处理
                if data.code != .fail {
                    observer.onNext(data)
                } else {
                    let apiError = APIError.error(wrong: data.message)
                    apiError.showHUD()
                    observer.onError(apiError)
                }
                
                observer.onCompleted()
            }, onError: { (error: Error) in
                // 在这里处理统一的错误
                
                let apiError = error as! APIError
                
                apiError.showHUD()
                
                observer.onError(apiError)
                observer.onCompleted()
            })
            
            return Disposables.create {
                disposable.dispose()
            }
        })
    }
```

可以发现，这一步的错误处理中，将指定的错误使用 HUD 进行了提示，这样我们在使用 API 的时候就不用考虑错误的问题了，当然某些接口如果返回错误，页面会有指定的操作的话依然是要指定 onError 的。当然，这样的做法是有点违背纯粹的设计模式的，这么做仅仅是为了统一处理某些不需要错误操作的用户操作。

有了上面这些，我们就可以开始针对不同的接口进行开发了，但是在 viewModel 中，也不能直接调用 `fetchData()` 方法，我们需要对每一个接口再写一层，将请求方法的指定、参数的组织、返回类型的指定这些过程放在这一层，对于外部是不需要知道这些内容的。而每一个接口，我们都需要根据不同的功能模块，将其放在同一个文件中，例如登录、注册、修改密码、修改用户信息等功能，我们可以创建一个 `API+Account.swift` 的文件，然后对 API 写一个 `extension`:

```
extension API {
    
    /// 登录
    ///
    /// - Parameters:
    ///   - email: 邮箱
    ///   - password: 密码
    /// - Returns: User
    class func login(email: String, password: String) -> Observable<UserResponse> {
        
        var param = [String: String]()
        
        param["mail"] = email
        param["password"] = Securty(string: password) // 对密码进行加密
        
        return getData(from: .login, parameters: param, returnType: UserResponse.self).map({ (response: UserResponse) -> UserResponse in
            return response
        })
    }
}
```
在 map 中，我们直接返回了请求的数据，也可以在中间进行一些其他的操作，例如添加缓存，这些功能都需要自己根据需求决定，有些是需要写在 viewModel 中有些需要写在这里。

**注意：在这里，返回的一定要是 UserResponse 类型，在最初的时候尝试过直接返回 response.user 。但是这样写单元测试会有问题，我们的 API 最好还是就完完整整的返回数据，数据过滤可以，但是不能精简数据，精简数据可能在 viewModel 的时候使用起来会很优雅，但是如果涉及到一个接口多处调用的时候就会有问题，有些地方需要某些数据，有些地方不需要，就会很尴尬。**

以上就是网络请求层的实现，这么一大段代码写下来后，当我们需要登录，我们在 viewModel 中的代码就会是：

```
API.login(email: email, password: password).subscribe(onNext: { (response: UserResponse) in
	   /// 避免 user 不存在
	   /// 因为 HandyJSON 在解析的时候，如果 datas 里面的数据为空
	   /// 或者干脆没有 datas 字段的时候，会正常解析，只要 code 和 msg 是对的
	   /// 这样做的好处是如果 model 中有些字段可能是空的就不会报错
	   guard let user = response.user else { return } 
	   
	   /// your code here
           
}).addDisposableTo(disposeBag)
```

## <a name="Cache"></a>3. 缓存

缓存方面，可用的方式就会比较多了，NSUserDefaults、文件存储、SQLite 数据库，都是可以做的，三种方式也各有优劣，用哪种缓存方式其实都可以，在缓存的时候主要还是从 model 到底层缓存，NSUserDefaults 主要用来存储小量数据，我们这里说的缓存都是按照大量数据来说的，因此推荐文件存储或数据库。在这里我使用了文件存储，使用了一个三方库叫做：[PINCache](https://github.com/pinterest/PINCache)，这个是从 OC 时代带过来的一个库。数据库的存储应该是最优秀的，在 Swift 下，使用数据库推荐 [Realm](https://realm.io/cn/docs/swift/latest/)。

说回 PINCahce，在 Realm 的强大下，PINCache 已经没有优势可言，相对于某些简单的数据，PINCache 还可以使用，但是如果是大量的数据，如果再要进行数据筛选等任务，PINCache 就会显得乏力，它只是数据存取而已。这里由于历史原因没有更新到 Realm，不过 PINCache 的使用可以给定一个思路。

不得不说，泛型和协议是让 swift 变得灵活的两大利器，因为 PINCache 只支持 NSCoding 类型的存储，因此我们的 Model 都将被转换为 JSON 字符串进行存取。使用泛型，在存取数据的时候可以直接对数据进行转换，示例代码如下：

```
/// 缓存层
/// 注意，这里只能存储遵循 HandyJSON 的类型的对象和一些遵循 NSCoding 的基本类型的对象
enum Cache: String {

    case userKey = "userKey"
    // ... 其他缓存
    
    /// 存储方法
    ///
    /// - Parameter 
    /// - item: 存储的对象
    func save(item : Any?) {
        
        guard let item = item else { return }
        
        var toSaveValue: NSCoding? = nil
        
        if item is HandyJSON {
            // 单纯的数据模型的存储
            let model = item as! HandyJSON
            if let toSaveJSONString = model.toJSONString() {
                toSaveValue = toSaveJSONString as NSCoding?
            }
        } else if item is NSCoding {
            // 是可以直接存储的内容，比如 String, Int 等遵循 NSCoding 协议的类型
            toSaveValue = (item as! NSCoding)
        }
        
        // 保存
        if  let toSaveValue = toSaveValue {
            PINCache.shared().setObject(toSaveValue, forKey: rawValue)
        }
    }    
    
    /// 获取数据
    ///
    /// - Parameters:
    ///   - type: 获取的数据要被转换的类型
    /// - Returns: DataType
    func get<D>(type: D.Type) -> D? {
        let cachedValue = PINCache.shared().object(forKey: rawValue)
        
        // 是一个模型
        if type is HandyJSON.Type,
            let cachedString = cachedValue as? String,
            let handyJsonType = type as? HandyJSON.Type {
            return handyJsonType.deserialize(from: cachedString) as? D
        }
        
        // 是一个不需要转换的类型
        return cachedValue as? D
    }
    
    /// 清理缓存
    func clear() {
        PINCache.shared().removeObject(forKey: rawValue)
    }
}
```
这写代码还只是基础缓存层，我们在使用的时候如果暴露如此多的内部代码，依然不够优雅，因此我们需要再进行一层的封装：

```
extension Cache {
    
    /// 登录或者注册后缓存的用户信息
    static var user: User? {
        get {
            guard isLogin else { return nil }
            return self.userKey.get(type: User.self)
        }
        set {
            guard let newValue = newValue,
                newValue.email != nil,
                newValue.userToken != nil else {
                
                isLogin = false
                return
            }
            
            isLogin = true
            lastLoginEmail = newValue.email
            self.userKey.save(item: newValue)
            APNS.shared.bindRegistrationID()
        }
    }
}
```

这样，我们在使用的时候就会比较方便了：

```
// 存
Cache.user = response.user

// 取
if let user = Cache.user {
	// Your code here
}
```

## <a name="mvvm"></a>4. 代码架构 - MVVM

### 4.1 MVVM

MVVM 架构中，Model 、View、ViewModel 是最基础的三个类，他们分别做着自己的工作。

> Model层，API请求的原始数据

> View层，视图展示，由viewController来控制

> ViewModel层，负责业务处理和数据转化

Model 层在前面已经说过，直接说明 View 层和 ViewModel 层。

在 iOS 开发中，我们的 View 一般都指 viewController，它负责整个页面的生命周期，为了进一步的将数据与 UI 解耦，数据方面只需要交给 ViewModel 来实现就可以，包括数据请求、数据处理、数据验证等工作。

在进行 UI 开发的时候，比较常用的有 [SnapKit](https://github.com/SnapKit/SnapKit)、[SVProgressHUD](https://github.com/SVProgressHUD/SVProgressHUD)、[MJRefresh](https://github.com/CoderMJLee/MJRefresh) 等三方库，还有一些类似 ActionSheetPicker、SDCycleScrollView 需要根据需求来确定是否使用，Swift 下比较推荐一个页面跳转的动画库 [Hero](https://github.com/lkzhao/Hero)。

下面以一个收藏列表的页面举例，它的 ViewModel 如下：

```
class WishListViewModel {
    
    var products = [Product]()
    
    var currentPage: Int = 1
    
}

// MARK: - API
extension WishListViewModel {
    
    /// 获取用户的收藏列表
    var fetchWishList: Observable<ProductListResponse> {
        get {
            currentPage = 1
            return API.fetchProductList(currentPage: currentPage, isWishList: true).map({ (response: ProductListResponse) -> ProductListResponse in
                self.products = response.listData.products
                self.currentPage = response.listData.pageNumber
                return response
            })
        }
    }
    
    /// 获取用户的收藏列表下一页
    var fetchWishListNextPage: Observable<ProductListResponse> {
        get {
            currentPage += 1
            return API.fetchProductList(currentPage: currentPage, isWishList: true).map({ (response: ProductListResponse) -> ProductListResponse in
                self.products.append(contentsOf: response.listData.products)
                self.currentPage = response.listData.pageNumber
                return response
            })
        }
    }
    
    /// 移除某一个商品
    ///
    /// - Parameter product: 商品
    /// - Returns: 移除的商品所处的位置
    func removeProduct(product: Product) -> Observable<Int>? {
        guard let index = index(of: product) else {
            return nil
        }
        
        return WishListViewModel.removeFromWishList(product: product).map { (_) -> Int in
            self.products.remove(at: index)
            return index
        }
    }
    
}

// MARK: - Private Methods
extension WishListViewModel {
    
    /// 获取一个商品的 Index
    ///
    /// - Parameter product: 商品
    /// - Returns: 位置，可能不存在
    fileprivate func index(of product: Product) -> Int? {
        
        for index in 0..<products.count {
            let existProduct = products[index]
            if existProduct.identity == product.identity {
                return index
            }
        }
        
        return nil
    }
    
}

// MARK: - Class Methods
// 这些方法写成类方法，是因为它们可以独立运行，并且会在其他位置单独使用
// 不要在 view 中越过 viewModel 去调用 API，也不要在其他 viewModel 中调用不符合其功能分工的 API
// 将某些可能会重用的功能在对应的 viewModel 中写出来，方便各个位置使用，减少重复代码
extension WishListViewModel {
    
    /// 检查某个商品是否在收藏列表
    ///
    /// - Parameter product: 商品
    /// - Returns: 是否在收藏
    static func checkAddedWishList(product: Product) -> Observable<Bool> {
        guard Cache.isLogin else {
            return Observable<Bool>.create({ (observer: AnyObserver<Bool>) -> Disposable in
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            })
        }
        return API.checkAddedWishList(product: product).map({ (response: CheckAddedWishListResponse) -> Bool in
            guard let checked = response.checkModel?.added else { return false }
            return checked
        })
    }
    
    /// 添加某个商品到收藏
    ///
    /// - Parameter product: 商品
    /// - Returns: 成功失败
    static func addToWishList(product: Product) -> Observable<Void> {
        return API.addToWishList(product: product).map({ (_) -> Void in
        })
    }
    
    /// 将某个收藏商品移除
    ///
    /// - Parameter product: 商品
    /// - Returns: 成功失败
    static func removeFromWishList(product: Product) -> Observable<Void> {
        return API.removeFromWishList(product: product).map({ (_) -> Void in
        })
    }
}
```

通过代码可以看到，所有相关的数据都在 viewModel 中实现，分页也是。这样，在我们的 viewcontroller 中，就只需要关心 UI 层面的内容就可以。示例代码如下：

```
class WishListViewController: UITableViewController {
    
    fileprivate let viewModel = WishListViewModel()
    
    var disposeBag = DisposeBag()

    deinit {
        disposeBag = DisposeBag()
    }
}

// MARK: - Life cycle
extension WishListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "My Favorites"
        tableView.separatorStyle = .none
        tableView.register(WishListCell.self, forCellReuseIdentifier: WishListCell.string)
        addRefresh()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.mj_header.beginRefreshing()
    }
}

// MARK: - Init
extension WishListViewController {
    
    /// 添加上拉刷新，下拉加载
    fileprivate func addRefresh() {
        addHeader()
        addFooter()
    }
    
    /// 添加上拉刷新
    fileprivate func addHeader() {
        addHeaderRefresh {
            self.tableView.mj_footer.resetNoMoreData()

            self.viewModel.fetchWishList.subscribe(onNext: { (response: ProductListResponse) in
                self.didFetchDataSuccess(with: response)
            }, onError: { (APIError: Error) in
                self.tableView.mj_header.endRefreshing()
                self.tableView.mj_footer.removeFromSuperview()
                self.addNetworkWrong()
            }).addDisposableTo(self.disposeBag)
        }
    }
    
    /// 添加下拉加载
    fileprivate func addFooter() {
        addFooterLoad {
            self.viewModel.fetchWishList.subscribe(onNext: { (response: ProductListResponse) in
                self.didFetchDataSuccess(with: response)
            }, onError: { (APIError: Error) in
                self.tableView.mj_footer.removeFromSuperview()
            }).addDisposableTo(self.disposeBag)
        }
    }
    
    /// 数据加载成功后的操作
    fileprivate func didFetchDataSuccess(with response: ProductListResponse) {
        if response.listData.pageNumber >= response.listData.totalPage {
            self.tableView.mj_footer.endRefreshingWithNoMoreData()
        } else {
            self.tableView.mj_footer.endRefreshing()
        }
        
        self.tableView.mj_header.endRefreshing()
        self.tableView.reloadData()
        
        self.makeEmptyIfNeed()
    }
    
    /// 如果没有数据，将会把页面设置为一个空页面的提示
    fileprivate func makeEmptyIfNeed() {
        if self.viewModel.products.count == 0 {
            addEmpty()

            self.tableView.mj_footer.removeFromSuperview()
        } else {
            self.removeEmpty()
            self.addFooter()
        }
    }
}

// MARK: - UITableView data source
extension WishListViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.products.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return WishListCell.height
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: WishListCell.string) as! WishListCell
        
        cell.product = viewModel.products[indexPath.row]
        cell.deleteCell.takeUntil(cell.rxReuse).subscribe(onNext: { (cell: WishListCell) in
            guard let product = cell.product else { return }
            self.removeCollected(product: product)
        }).addDisposableTo(disposeBag)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PushManager.pushProductDetail(product: viewModel.products[indexPath.row])
    }
    
}

// MARK: - API
extension WishListViewController {
    
    fileprivate func removeCollected(product: Product) {
        HUD.show("Removing...")
        viewModel.removeProduct(product: product)?.subscribe(onNext: { (index: Int) in
            self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .right)
            self.makeEmptyIfNeed()
            HUD.dismiss()
        }).addDisposableTo(disposeBag)
    }

}
```

### 4.2 高内聚、低耦合

一般 View  和 ViewModel 都是面向业务来进行开发的，说到业务就必须要提出一个问题，那就是可扩展性和后期维护。要做到可扩展和易维护，就必然会提到一个概念：高内聚低耦合。在开发的时候，一定要考虑如果有新的需求，现有的实现方式是否能做到快速修改和扩展。在这里分享一下我个人的做法：

#### 4.2.1将不同的功能单独拿出来，在需要的地方尽量做到一行代码调用

##### 推送

将推送所有功能单独成类，包括注册推送、激活推送、处理推送，在 AppDelegate 中，我们只需要单独调用这个类就可以，不用在 Appdelegate 里面写一大堆代码了。

##### 支付

支付单独写出来后，在不同的页面调起支付，只需要一行代码，非常方便。

##### 分享
现在一些三方供应商已经将分享功能封装的非常简单了，但是作为使用者，还是需要通过 key 注册，不同的分享结果需要不同的处理，在业务代码中，写少量这样的代码也是非常让人烦躁的。

##### 更多

这里基本上是对三方一些需要 key 来进行注册，或者在 AppDelegate 里面需要启用的，为了不让 AppDelegate 里面的代码过多，我们有必要将这些逻辑分开来，在 AppDelegate 里面看到的应该只有各个功能的调用，而不是任何实际的功能代码。包括没有使用 `main.storyboard` 的时候进行页面架构组织的代码，也应该提取出来，写一个 extension，在里面实现。

### 4.2.2 针对一些特殊类型的控件，能做到写成一个独立的类，在需要的地方直接调用

例如我们的电商平台，有很多控件是可以通用的，即使外观不一样，但是功能是一致的，也是可以单独写出来并且自定义达到目的的：

##### 循环滚动

SDCycleScrollView 很多人都在用，但是据我所知的使用方法全都是直接创建调用，因为很多地方都可以通用，所以会写出很多重复的代码，将 SDCycleScrollView 自己封装，更适合你的需求，调用起来更方便。下面是我封装后的调用：
 
```
// 创建
fileprivate let bannerView = CycleScrollView.createForNewHome()
 	
// 添加
headerView.addSubview(bannerView)
 	
// 传参
bannerView.imageUrls = viewModel.newBannerImageURLs
 	
// 点击事件
bannerView.selected.subscribe(onNext: { (selectedIndex: Int) in
	// Your code here
}).addDisposableTo(disposeBag)
    
// 真正做到：创建、使用。而不用去关心其内部实现，也不会对业务代码造成任何侵略
```
##### 输入框

将输入框重新封装，加入 ActionSheetPicker 功能，传入数据源，设置输入方式，就可以直接调用，UI 也可以自定义，输入框的左侧/右侧可以自己添加图片或者标题，也可以设定输入框的 returnKeyType 等。下面是示例：

```
let countryText = InputView.creat()
	
countryText.inputText.placeholder = "Country"
countryText.inputText.font = UIFont.mediumFont(size: .minorSize)
// 设置右边的图片
countryText.rightImage = #imageLiteral(resourceName: "textOpen")
// 设置点击类型，分别为 .left .all .right 代表着不同区域可点击
countryText.clickType = .all
// 是否必填，使用 isCompleted 来确定是不是完成填写了，如果 isNeccessary 是 false，那么 isCompleted 将会直接为 true
countryText.isNeccessary = true
// 下一个要获取焦点的输入视图，如果设置了，returnKeyType 就会是 next
countryText.nextInputView = stateText
// ActionSheetPicker 的数据源
countryText.singleSelectionDatasource = viewModel.countryNames
// 选择了某个 picker 的回调
countryText.selectedIndex = { (index, Value) in
	self.updateStateInputView()
}
addSubview(countryText)
```
##### 倒计时控件

有很多抢购的商品或者活动会需要倒计时控件，统一写一个倒计时控件，可以自定 UI，直接使用就可以进入倒计时，重用问题也可以直接被解决。

##### 动画按钮

手指按下会随着手指缩小，手指放开会锁着手指放大的按钮

##### 选项卡

封装了一个 segmentView 的视图，可以自己调整 UI，也是达到创建、使用，而不用关心内部实现

##### 价格标签

有现价原价，原价会有删除线，可以分别设置标题，可以设置两个价格的左右上下相对位置等。

##### 更多

在这里会有很多可以做的，千万不要在业务逻辑中写一大堆组建视图的代码，这会让业务代码的体量非常大，在修改和扩展的时候也会非常痛苦。即使是很多三方库已经写的比较精简，但是这些三方库都是非常抽象的抽象，在具体使用的时候还是会有很多自己自定义的代码，这些代码，单独写出来也是非常有必要的。


### 4.2.3 将一些重复的代码单独拿出来，写成 extension 调用

#####下拉刷新、上拉加载
上面的例子中应该看到了 `addHeaderRefresh{}` 方法，它就是封装好的：

```
// UICollectionViewController 也会有一个这样的 extension，是为了尽力去减少业务逻辑中的代码
// 当然也可以写给 UIScrollView
// 但是我个人比较习惯使用 UITableViewController 和 UICollectionViewController，因此这么做了
extension UITableViewController {
    
    func addHeaderRefresh(refreshBlok: @escaping () -> ()) {
        guard let refreshHeader = MJRefreshGifHeader(refreshingBlock: {
            refreshBlok()
        }) else { return }
        
        let gitImages = gifImages
        let duration = Double(gitImages.count)*0.03
        refreshHeader.setImages([#imageLiteral(resourceName: "staticLoad")], duration: duration, for: .idle)
        refreshHeader.setImages([#imageLiteral(resourceName: "staticLoad")], duration: duration, for: .pulling)
        refreshHeader.setImages(gifImages, duration: duration, for: .refreshing)
        refreshHeader.lastUpdatedTimeLabel.isHidden = true
        refreshHeader.stateLabel.isHidden = true
        
        tableView.mj_header = refreshHeader
    }
    
    func addFooterLoad(loadBlock: @escaping () -> Void) {
        guard let loadFooter = MJRefreshAutoGifFooter(refreshingBlock: { 
            loadBlock()
        }) else { return }
        
        let gitImages = gifImages
        let duration = Double(gitImages.count)*0.03
        loadFooter.setImages([#imageLiteral(resourceName: "staticLoad")], duration: duration, for: .idle)
        loadFooter.setImages([#imageLiteral(resourceName: "staticLoad")], duration: duration, for: .pulling)
        loadFooter.setImages(gifImages, duration: duration, for: .refreshing)
        
        loadFooter.setTitle("", for: .idle)
        loadFooter.setTitle("Release to Load More", for: .pulling)
        loadFooter.setTitle("Loading More", for: .refreshing)
        loadFooter.setTitle("No more item.", for: .noMoreData)
        
        tableView.mj_footer = loadFooter
	}
}
```
	
##### 添加一个圆角阴影

之前的设计中，大部分视图都是带圆角和阴影的，众所周知的是在开发中使用 UIKit 提供的添加圆角和阴影的方法会非常消耗内存，造成卡顿是家常便饭。于是我们设计提供了一张可扩展的图片，只要在视图上根据大小修改图片尺寸并添加就可以了。但是这个过程也是非常复杂的，要处理一些特殊情况，如果每个用到的地方都分别写一段代码来实现，会非常痛苦的。经过给 UIView 写一个 extension，提供了一个暴露在外部的方法来添加圆角和阴影，具体的实现在内部使用 private func 完成。在封装后给视图添加这个效果的代码就可以精简为：

```
// 一行代码调用，精简到极致，侵略性非常低
// 后来的需求中，去掉了所有的圆角和阴影效果，对于代码来说，删除这一段就可以了，完全不影响原先的业务逻辑
productView.addSelfRadiusShaow()
```
	
##### 更多

上面两个是比较典型的例子，还有很多都可以这么做，这里就不一一罗列了。需要注意的是，虽然在最初开发的时候可能会比较复杂，需要思考不同的情况并进行处理，但是如果坚持这样做，在后期维护和新的类似功能开发的时候，你会非常感谢你自己的。

### 4.2.4 能统一进行调用的，统一调用

##### 页面逻辑

为了进一步将每个页面独立及解耦代码，我设计了一个页面逻辑类 `PushManager`，根据自己的页面架构，写出每一个页面的跳转代码，在业务逻辑中，需要跳转页面的时候直接调用 PushManager 的对应方法，相关的数据也是从这里来传递的。

相关代码如下，注意在这里不要过度关注跳转具体页面内部的代码，例如 `pushProductGrid()` 的内部实现，这些只是用来做示例的：

```
// 最基础的 UITabbarController
var tabBarVC: UITabBarController {
    get {
        guard let tabbarVC = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController else {
            return UITabBarController()
        }

        return tabbarVC
    }
}

// 当前正在显示的 NavigationController
var centerViewController: RTRootNavigationController? {
    get {
        guard let navc = tabBarVC.selectedViewController as? RTRootNavigationController else {
            return nil
        }
        
        return navc
    }
}

// 首页
var rootHomeViewController: NewHomeTableViewController? {
    get {
        guard let navc = tabBarVC.viewControllers?.first as? RTRootNavigationController,
            let homeContainerVC = navc.viewControllers.first as? RTContainerController,
            let homeVC = homeContainerVC.contentViewController as? NewHomeTableViewController else {
            return nil
        }
        
        return homeVC 
    }
}

class PushManager {
    
    /// pop tabbar 的每个 navigationcontroller to root
    class func popAll() {
        for viewcontroller in tabBarVC.viewControllers! {
            if let navc = viewcontroller as? UINavigationController {
                navc.popToRootViewController(animated: false)
            }
        }
    }
    
    /*
        到主页
     */
    class func pushHome() {
        tabBarVC.selectedIndex = 0
        popAll()
    }
    
    /*
        到分类页
     */
    class func pushCategory() {
        tabBarVC.selectedIndex = 1
        popAll()
    }
    
    /*
        到购物车
     */
    class func pushCart() {
        tabBarVC.selectedIndex = 2
        popAll()
    }
    
    /// 跳转一个新的购物车
    class func pushNewCart() {
        let cartVC = CartViewController()
        
        cartVC.hidesBottomBarWhenPushed = true
        centerViewController?.isHeroEnabled = false
        centerViewController?.pushViewController(cartVC, animated: true, complete: { (completed: Bool) in
            
        })
    }
    
    /*
        到个人中心
     */
    class func pushMe() {
        tabBarVC.selectedIndex = 3
        popAll()
    }
    
    /// 跳转商品列表 - 列表模式（两列）
    ///
    /// - Parameters:
    ///   - category: 分类
    ///   - flashSale: 闪购
    ///   - searchKeyWord: 搜索关键字
    ///   - sort: 排序
    ///   - filters: 筛选，filterID;filterID;filterID
    ///   - title: 页面标题
    class func pushProductList(category: ProductCategory? = nil, flashSale: FlashSale? = nil, searchKeyWord: String? = nil, sort: String? = nil, filters: String? = nil, title: String? = "Popreal") {
        pushProductGrid(category: category,
                        flashSale: flashSale,
                        searchKeyWord: searchKeyWord,
                        sort: sort,
                        filters: filters,
                        withType: .two,
                        title: title)
    }
    
    /// 跳转商品列表 - 网格模式
    ///
    /// - Parameters:
    ///   - category: 分类
    ///   - flashSale: 闪购
    ///   - searchKeyWord: 搜索关键字
    ///   - sort: 排序
    ///   - filters: 筛选
    ///   - withType: 展示类型
    ///   - title: 页面标题(默认标题，如果对应的 category/flashsale 有名字，将设置为对应的名字)
    class func pushProductGrid(category: ProductCategory? = nil, flashSale: FlashSale? = nil, searchKeyWord: String?, sort: String? = nil, filters: String? = nil, withType: ProductListShowType, title: String? = "Popreal") {
        let productGrid = ProductGridViewController(collectionViewLayout: withType.layout)
        productGrid.title = title
        productGrid.category = category
        productGrid.flashSale = flashSale
        productGrid.searchKeyWord = searchKeyWord
        productGrid.sortCode = sort
        if let filters = filters {
            productGrid.filterIds = filters.components(separatedBy: ";")
        }
        productGrid.showType = withType
        productGrid.hidesBottomBarWhenPushed = true
        
        centerViewController?.isHeroEnabled = false
        centerViewController?.heroModalAnimationType = .push(direction: .right)
        centerViewController?.pushViewController(productGrid, animated: true)
    }
}
```

这样做来，我们本来要跳转商品列表的打断代码就被缩略成了这么一个方法，其调用方式也会非常简单：

```
PushManager.pushProductList(category: category)
```
页面逻辑的封装在小型项目里面会比较方便，但是如果有大型项目，多人合作就会会出现问题。但这也是可以解决的，不同的人负责的不同模块，可以创建自己的 extension 并写到不同的文件里，自己进行维护，前提是有一个人来专门维护基本方法。

## <a name="imageload"></a>5. 图片加载
图片加载中间的缓存策略等是非常重要的，内存 - 沙盒 - 网络请求，三级缓存策略是常用的缓存策略，SDWebImage 在 objective-c 时期陪伴广大开发者走过了非常愉快的时光，而到了 Swift 时代，onevcat 为我们整个开发者贡献了原汁原味的 Swift 版本网络图片请求库 [Kingfisher](https://github.com/onevcat/Kingfisher)。在这里要多啰嗦一句，SDWebImage 和 Kingfisher 的源代码希望都阅读一下，可以为你提供很多优秀的思路，尤其是 Kingfisher，绝对让你对 Swift 的认识更加深入。

面对所有的三方库，都会写一个中间层，以避免后期需求改动需要修改三方库的使用方式，这样就可以只在这一层修改而不会对业务代码造成任何威胁，针对 Kingfisher 也是：

```
public typealias ImageLoaderCompletionHandler = ((_ image: UIImage?) -> ())

// ImageLoader 是一个图片加载类，它的任务只是加载出来图片，不会对 UIImageView 做任何操作
// 
// 写这个类是为了某些只需要图片，但不需要显示这张图片的需求，主要还是利用了 Kingfisher 的取图片操作
class ImageLoader {
    
    /// 根据一个 URL 获取图片，可能是内存、沙盒、网络请求来的
    ///
    /// - Parameters:
    ///   - url: 图片链接
    ///   - complete: 加载完成
    class func retrieveImage(url: String, complete: @escaping ImageLoaderCompletionHandler) {
        KingfisherManager.shared.retrieveImage(with: URL(string: url)!,
                                               options: KingfisherManager.shared.defaultOptions,
                                               progressBlock: nil,
                                               completionHandler: { (image: Image?, error: Error?, cacheType: CacheType, url: URL?) in
                                                complete(image)
        })
    }
    
}

// 这个 extension 添加了一个加载和取消加载网络图片的方法
extension UIImageView {
    
    /// 加载网络图片，会自动设定默认图片，并且以淡入淡出的效果切换新图片
    ///
    /// - Parameters:
    ///   - urlString: 图片链接
    ///   - placeholder: 默认图片
    ///   - completionHandler: 加载完成
    func load(with urlString: String?, placeholder: UIImage = #imageLiteral(resourceName: "placeholderOther"), completionHandler: CompletionHandler? = nil) {
        guard let urlString = urlString else { return }
        let loadUrl = URL(string: urlString)
        cancelLoad()
        self.kf.setImage(with: loadUrl, placeholder: placeholder) { (image: Image?, error: NSError?, cacheType: CacheType, url: URL?) in
            if error != nil || image == nil || cacheType != .none { return }
            UIView.transition(with: self,
                              duration: 0.4,
                              options: .transitionCrossDissolve,
                              animations: { 
                                self.image = image
                              },
                              completion: { (completed: Bool) in
                                if let completionHandler = completionHandler {
                                    completionHandler(image, error, cacheType, url)
                                }
                              })
        }
        
    }
    
    /// 取消加载图片
    func cancelLoad() {
        self.kf.cancelDownloadTask()
    }
}
```

这样写以后，在加载图片的时候就可以写的非常简便：

```
productImageView.load(with: product.imageURL)
```
当然想要在不同的需求下自己定义加载效果和默认图片也是可以的。

## <a name="Tools"></a>6. 工具类

Swift 是一个非常灵活的语言，在 OC 下，工具类中的宏定义非常多，而在 Swift 下，可以直接写一个方法、一个变量、一个 extension，使用起来也是相当方便。特别推荐一个强大的三方库 [Dollar](https://github.com/ankurp/Dollar)，它给 Array、String 等添加了很多非常有趣方便的功能。

下面分享一些我个人常用的工具类方法：

```
// 快速使用全项目都将要用到的弹簧动画
func bounceAnimation(withDuration duration: TimeInterval = 0.5,
                     delay: TimeInterval = 0,
                     usingSpringWithDamping dampingRatio: CGFloat = 0.65,
                     initialSpringVelocity velocity: CGFloat = 0,
                     options: UIViewAnimationOptions = .curveEaseInOut,
                     animations: @escaping () -> Swift.Void,
                     completion: ((Bool) -> Swift.Void)? = nil) {
    UIView.animate(withDuration: duration,
                   delay: delay,
                   usingSpringWithDamping: dampingRatio,
                   initialSpringVelocity: velocity,
                   options: options,
                   animations: {
                    animations()
    }, completion: completion)
}

// 快速使用全项目都将要用到的普通动画
func viewAnimation(withDuration duration: TimeInterval = 0.3,
                   animations: @escaping () -> Swift.Void,
                   completion: ((Bool) -> Swift.Void)? = nil) {
    UIView.animate(withDuration: duration,
                   animations: { 
                    animations()
    }, completion: completion)
}

// MARK: - UIDevice Extension
extension UIDevice {
    static let isLandScape = (UIDevice.current.orientation == .landscapeLeft ||  UIDevice.current.orientation == .landscapeRight)
    
    static let isiPad = (UIDevice.current.userInterfaceIdiom == .pad)
    static let isiPhone = (UIDevice.current.userInterfaceIdiom == .phone)
    
    static let isiPhone4 = ((UIDevice.isiPhone) && (UIScreen.height < 568.0))
    static let isiPhone5 = ((UIDevice.isiPhone) && (UIScreen.height == 568.0))
    static let isiPhone6 = ((UIDevice.isiPhone) && (UIScreen.height == 667.0))
    static let isiPhone6p = ((UIDevice.isiPhone) && (UIScreen.height == 736.0))
    static let isiPhoneX = ((UIDevice.isiPhone) && (UIScreen.height == 812.0))
    
    static let isiOS8AndLater = (Float(UIDevice.current.systemVersion)! >= Float(8.0))
    static let isiOS8Family = (Float(UIDevice.current.systemVersion)! >= Float(8.0)) && (Float(UIDevice.current.systemVersion)! < Float(9.0))
    static let isiOS9Family = (Float(UIDevice.current.systemVersion)! >= Float(9.0)) && (Float(UIDevice.current.systemVersion)! < Float(10.0))
    static let isiOS10Family = (Float(UIDevice.current.systemVersion)! >= Float(10.0)) && (Float(UIDevice.current.systemVersion)! < Float(11.0))
    
    static var sysNameVersion: String {
        get {
            return UIDevice.current.systemName + " " + UIDevice.current.systemVersion
        }
    }
}

// MARK: - UIScreen Extension
extension UIScreen {
    // 屏幕宽度
    static let width = UIScreen.main.bounds.size.width
    // 屏幕高度
    static let height = UIScreen.main.bounds.size.height
}

/// 状态栏高度
var statusBarHeight: CGFloat {
    get {
        return UIDevice.isiPhoneX ? 44 : 20
    }
}

/// 导航栏高度
var navigationBarHeight: CGFloat {
    get {
        return 44;
    }
}

/// tabbar 的内容高度
var tabBarContentHeight: CGFloat = 49

/// tabbar 的高度
var tabBarHeight: CGFloat {
    get {
        return tabBarContentHeight + bottomBarBottomHeight
    }
}

/// toolbar 的内容高度
var toolbarContentHeight: CGFloat = 49

/// toolbar 的高度
var toolBarHeight: CGFloat {
    get {
        return toolbarContentHeight + bottomBarBottomHeight
    }
}

/// toolbar/tabbar 底部的高度
/// 如果是 iPhoneX 那么这个高度就是 34 否则为 0
var bottomBarBottomHeight: CGFloat {
    get {
        return UIDevice.isiPhoneX ? 34 : 0
    }
}

// MARK: - Alert
func alert(title: String = "", message: String = "", confirmTitle: String = "", cancelTitle: String = "", confirm: @escaping () -> (), cancel:  (() -> ())? = nil) {
    let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
    
    if confirmTitle.length > 0 {
        alert.addAction(UIAlertAction.init(title: confirmTitle, style: .default, handler: { (action: UIAlertAction) in
            confirm()
        }))
    }
    
    if cancelTitle.length > 0 {
        alert.addAction(UIAlertAction.init(title: cancelTitle, style: .default, handler: { (action: UIAlertAction) in
            if let cancel = cancel {
                cancel()
            }
        }))
    }
    
    centerViewController?.present(alert, animated: true, completion: nil)
}
```

## <a name="UnitTest"></a>7. 单元测试

单元测试是一个非常重要的功能，只有开始写单元测试，你才会知道自己的代码是否是真的低耦合。在这里推荐一个 Swift 的单元测试框架 [Quick](https://github.com/Quick/Quick)，其思路非常好，每一例测试都会有 description，每一例测试的每一个操作都可以添加 description，这样你在测试的时候就可以非常方便的定位到错误。

具体代码就不贴出来了，说说思路：

* 封装抽象：还是封装抽象，单元测试也是非常重要的代码，也需要一些基础类，一定要给自己写一个基础的测试类，用来追踪测试，返回可识别的错误信息，这就是 Quick 干了的事情。同理在单元测试写代码的时候，也可以考虑将三方的代码进行近一次的合适你的项目的封装。
* 接口测试：每一个接口可以独立进行测试，多个接口也需要进行联合测试，这样整个流程就会很方便的测试完成，有什么问题会很快发现并解决。
* 功能测试：例如最开始的 WishList 的功能，有了非常独立的 viewModel 我们就可以很轻松的测试到整个流程，从获取数据到操作数据，这些都可以测试。
* UI 测试：Xcode 提供了 UI 测试的功能，已经非常方便了，但是如果仅仅是 UI 层面的测试，其实自己进行实际点击会更加方便。

需要特别说明的是，希望所有的 iOS 开发者都能注意到单元测试的重要性，它能帮助你减少 Bug，能帮你找到自己的问题，能帮你优化自己的代码，真的是百利而无一害。**千万不要怕麻烦！**单元测试并不是可以向其他同事展现工作成果的工作，有一些项目的单元测试代码比原代码还要多，这都是正常的，越能思考到各种问题，越能让自己的代码更加健壮，更能提升自己的技术能力。

## <a name="Safe"></a>8. 安全

### 接口安全

尽量使用 https，其安全性要比 http 高出许多。

关键信息一定要加密，RSA 非对称加密等技术的实现也不是什么困难的技术，但是可以让你的数据达到一个非常安全的级别。

使用验证，通过时间戳+参数+特殊字符进行多次自定义的复杂加密，得出的串作为验证串，也能减少被攻击的可能性。

还有 App 自身的安全问题，有很多种方法来提高安全级别。这里只是希望各位在新建一个项目做架构的时候能思考到安全这个问题，不做过多的解释，需要的可以在互联网按照自己喜爱的方式查找相关内容。

## 9. 更多

在现在的开发环境来看，在一个 Swift 项目中，存在一定量的 Objective-C 代码是不可避免的，以及一些库还是 Objective-C 的，不得不使用。原则是，尽力不要使用 Objective-C 代码。遇见一个问题的时候，多查查相关内容，即使这个问题会花费你很多时间，也一定要想办法解决，经历困难解决问题才是提升的捷径。哦，对了，还有一个捷径，那就是阅读代码，Github 上有很多优秀的代码，阅读其源代码可以帮助你更加快速的学习到别人已经验证了无数遍的模式。

当然这样的框架思路中应该还有一些问题及可优化的地方，还需要漫长的试验才能发现，也希望认真看完的朋友多多提些意见，可以共同提高。



