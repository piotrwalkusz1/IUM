import 'dart:async';
import 'dart:convert';

import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/model/product.dart';
import 'package:frontend/service/product_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import "package:http/http.dart" as http;

GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId:
      '1021533878214-cs69h67atkvanvqa62v2s45engm04pme.apps.googleusercontent.com',
  scopes: <String>['email'],
);

void main() {
  runApp(
    MaterialApp(
      title: 'Magazyn',
      home: App(),
    ),
  );
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

enum Pages { Products, Product, CreateProduct, Increase, Decrease }

class _AppState extends State<App> {
  GoogleSignInAccount _currentUser;
  String _basicToken;
  Pages _currentPage = Pages.Products;
  List<Product> _products;
  Product _product;
  String _login;
  String _password;
  bool _isManager = false;
  String _decreasePageError = "";
  List<Map> _commands = new List();
  String _synchronizationErrors = "";
  int nextProductId = 0;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
        if (_currentUser != null) {
          setState(() {
            _isManager = false;
          });
          goToProductsPage();
        }
      });
    });
    _googleSignIn.signInSilently();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Magazyn'),
          actions: isSignIn()
              ? <Widget>[
                  FlatButton(
                    child: const Text('WYLOGUJ'),
                    onPressed: _handleSignOut,
                    textColor: Colors.white,
                  )
                ]
              : [],
        ),
        body: ConstrainedBox(
            constraints: const BoxConstraints.expand(), child: _buildBody()));
  }

  Future<void> _handleSignOut() {
    _googleSignIn.disconnect();
    setState(() {
      _basicToken = null;
    });
  }

  Future<void> _handleSignIn() async {
    String credentials = "$_login:$_password";
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String token = stringToBase64.encode(credentials);

    http.Response response = await http.get(
        'http://192.168.178.34:8080/api/users/current-user/roles',
        headers: {'Authorization': 'Basic $token'});

    if (response.statusCode != 200) {
      return;
    }

    setState(() {
      _basicToken = token;
      _isManager = jsonDecode(response.body).contains("ROLE_MANAGER");
    });

    goToProductsPage();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  bool isSignIn() {
    return _currentUser != null || _basicToken != null;
  }

  Widget _buildBody() {
    if (!isSignIn()) {
      return _buildSignInPage();
    } else {
      switch (_currentPage) {
        case Pages.Products:
          return _buildProductsPage();
        case Pages.Product:
          return _buildProductPage();
        case Pages.CreateProduct:
          return _buildCreateProductPage();
        case Pages.Increase:
          return _buildIncreasePage();
        case Pages.Decrease:
          return _buildDecreasePage();
      }
    }
  }

  Widget _buildProductsPage() {
    List<Widget> children = List();

    children.add(Expanded(
        child: ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          RaisedButton(
              child: const Text('SYNCHRONIZUJ'),
              onPressed: synchronizeProductsAndFetch),
          RaisedButton(
              child: const Text('UTWÓRZ'), onPressed: goToCreateProductPage)
        ],
      ),
    )));

    if (_synchronizationErrors.isNotEmpty) {
      children.add(Expanded(
          flex: 2,
          child: SingleChildScrollView(child: Text(_synchronizationErrors))));
    }

    if (_products != null) {
      List<Widget> productList =
          _products.map((product) => _buildProductRow(product)).toList();
      children.add(Expanded(
          flex: 10,
          child:
              ListView(padding: EdgeInsets.all(16.0), children: productList)));
    }

    return ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround, children: children),
    );
  }

  Widget _buildProductPage() {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Nazwa'),
              initialValue: _product.name,
              onChanged: (value) {
                _product.name = value;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Producent'),
              initialValue: _product.manufacturer,
              onChanged: (value) {
                _product.manufacturer = value;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Cena'),
              initialValue: _product.price.toString(),
              inputFormatters: [CurrencyTextInputFormatter(symbol: "zł ")],
              keyboardType: TextInputType.number,
              onChanged: (value) {
                try {
                  _product.price =
                      double.parse(value.substring(3).replaceAll(",", ""));
                } catch (error) {}
              },
            ),
            TextFormField(
                enabled: false,
                decoration: InputDecoration(labelText: 'Ilość'),
                initialValue: _product.quantity.toString()),
            Expanded(
                child: ConstrainedBox(
              constraints: const BoxConstraints.expand(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RaisedButton(
                          child: const Text('ZAPISZ'),
                          onPressed: _handleSaveProduct),
                      RaisedButton(
                          child: const Text('DODAJ'),
                          onPressed: goToIncreasePage),
                      RaisedButton(
                          child: const Text('WYŚLIJ'),
                          onPressed: goToDecreasePage),
                      RaisedButton(
                          child: const Text('USUŃ'),
                          onPressed: _isManager ? _handleRemoveProduct : null)
                    ],
                  ),
                  Row(
                    children: [
                      RaisedButton(
                          child: const Text('WRÓC'),
                          onPressed: goToProductsPage)
                    ],
                  )
                ],
              ),
            ))
          ])),
    );
  }

  Widget _buildIncreasePage() {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            TextFormField(
              key: Key("1"),
              decoration:
                  InputDecoration(labelText: 'Liczba dodanych produktów'),
              initialValue: '0',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                try {
                  _product.quantity = int.parse(value);
                } catch (error) {}
              },
            ),
            Expanded(
                child: ConstrainedBox(
              constraints: const BoxConstraints.expand(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  RaisedButton(
                      child: const Text('ZATWIERDŹ'),
                      onPressed: handleIncrease),
                  RaisedButton(
                      child: const Text('ANULUJ'), onPressed: goToProductsPage)
                ],
              ),
            ))
          ])),
    );
  }

  Widget _buildDecreasePage() {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            TextFormField(
              key: Key("2"),
              decoration:
                  InputDecoration(labelText: 'Liczba wysłanych produktów'),
              initialValue: '0',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                try {
                  _product.quantity = int.parse(value);
                } catch (error) {}
              },
            ),
            Text(_decreasePageError),
            Expanded(
                child: ConstrainedBox(
              constraints: const BoxConstraints.expand(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  RaisedButton(
                      child: const Text('ZATWIERDŹ'),
                      onPressed: handleDecrease),
                  RaisedButton(
                      child: const Text('ANULUJ'), onPressed: goToProductsPage)
                ],
              ),
            ))
          ])),
    );
  }

  void handleIncrease() {
    Product productToUpdate =
        _products.firstWhere((element) => element.id == _product.id);

    setState(() {
      if (_product.id.startsWith("-")) {
        Map command =
            _commands.firstWhere((element) => element["type"] == "Add");
        command["quantity"] += _product.quantity;
      } else {
        _commands.add({
          "type": "Increase",
          "productId": _product.id,
          "delta": _product.quantity
        });
      }

      productToUpdate.quantity += _product.quantity;
    });

    goToProductsPage();
  }

  void handleDecrease() {
    Product productToUpdate =
        _products.firstWhere((element) => element.id == _product.id);

    if (productToUpdate.quantity < _product.quantity) {
      setState(() {
        _decreasePageError = "Niedostateczna ilość produktów";
      });
      return;
    }

    setState(() {
      if (_product.id.startsWith("-")) {
        Map command =
            _commands.firstWhere((element) => element["type"] == "Add");
        command["quantity"] -= _product.quantity;
      } else {
        _commands.add({
          "type": "Decrease",
          "productId": _product.id,
          "delta": _product.quantity
        });
      }
      productToUpdate.quantity -= _product.quantity;
    });

    goToProductsPage();
  }

  Widget _buildCreateProductPage() {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Nazwa'),
              initialValue: _product.name,
              onChanged: (value) {
                _product.name = value;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Producent'),
              initialValue: _product.manufacturer,
              onChanged: (value) {
                _product.manufacturer = value;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Cena'),
              initialValue: _product.price.toString(),
              inputFormatters: [CurrencyTextInputFormatter(symbol: "zł ")],
              keyboardType: TextInputType.number,
              onChanged: (value) {
                try {
                  _product.price =
                      double.parse(value.substring(3).replaceAll(",", ""));
                } catch (error) {}
              },
            ),
            Expanded(
                child: ConstrainedBox(
              constraints: const BoxConstraints.expand(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  RaisedButton(
                      child: const Text('ZAPISZ'),
                      onPressed: _handleCreateProduct),
                  RaisedButton(
                      child: const Text('ANULUJ'), onPressed: goToProductsPage)
                ],
              ),
            ))
          ])),
    );
  }

  void _handleSaveProduct() {
    Product productToUpdate =
        _products.firstWhere((element) => element.id == _product.id);

    setState(() {
      if (productToUpdate.id.startsWith("-")) {
        Map command =
            _commands.firstWhere((element) => element["type"] == "Add");
        command["data"]["name"] = _product.name;
        command["data"]["manufacturer"] = _product.manufacturer;
        command["data"]["price"] = _product.price;
      } else {
        _commands.removeWhere((element) =>
            element["type"] == "Update" &&
            element["data"]["id"] == _product.id);
        _commands.add({
          "type": "Update",
          "data": {
            "id": _product.id,
            "name": _product.name,
            "manufacturer": _product.manufacturer,
            "price": _product.price
          }
        });
      }

      productToUpdate.name = _product.name;
      productToUpdate.manufacturer = _product.manufacturer;
      productToUpdate.price = _product.price;
    });
  }

  void _handleCreateProduct() {
    setState(() {
      _commands.add({
        "type": "Add",
        "data": {
          "name": _product.name,
          "manufacturer": _product.manufacturer,
          "price": _product.price
        },
        "quantity": 0
      });
      _products.add(Product(
        id: "-" + (nextProductId++).toString(),
        name: _product.name,
        manufacturer: _product.manufacturer,
        price: _product.price,
        quantity: 0,
      ));
    });

    goToProductsPage();
  }

  void _handleRemoveProduct() {
    Product productToUpdate =
        _products.firstWhere((element) => element.id == _product.id);

    setState(() {
      _products.removeWhere((element) => element.id == _product.id);

      if (productToUpdate.id.startsWith("-")) {
        _commands.removeWhere((element) =>
            element["type"] == "Add" && element["data"]["id"] == _product.id);
      } else {
        _commands.add({"productId": _product.id});
      }
    });

    goToProductsPage();
  }

  Widget _buildProductRow(Product product) {
    return ListTile(
      title: Text(product.name),
      onTap: () => goToProductPage(product),
    );
  }

  void goToProductsPage() {
    setState(() {
      _currentPage = Pages.Products;
    });
  }

  void goToProductPage(Product product) {
    setState(() {
      _currentPage = Pages.Product;
      _product = Product.copy(product);
    });
  }

  void goToCreateProductPage() {
    setState(() {
      _currentPage = Pages.CreateProduct;
      _product = Product();
      _product.price = 0;
    });
  }

  void goToIncreasePage() {
    setState(() {
      _currentPage = Pages.Increase;
      _product.quantity = 0;
    });
  }

  void goToDecreasePage() {
    setState(() {
      _currentPage = Pages.Decrease;
      _product.quantity = 0;
      _decreasePageError = "";
    });
  }

  void synchronizeProductsAndFetch() {
    synchronizeProducts(_currentUser, _basicToken, _commands)
        .then((synchronizationResponse) {
      setState(() {
        _commands = List();
        _synchronizationErrors = synchronizationResponse;
      });

      return fetchProducts(_currentUser, _basicToken).then((products) {
        setState(() {
          _products = products;
        });
      });
    });
  }

  Widget _buildSignInPage() {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          TextFormField(
            decoration: InputDecoration(labelText: 'Login'),
            onChanged: (value) {
              _login = value;
            },
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Hasło'),
            onChanged: (value) {
              _password = value;
            },
            obscureText: true,
          ),
          RaisedButton(
            child: const Text('ZALOGUJ'),
            onPressed: _handleSignIn,
          ),
          RaisedButton(
            child: const Text('ZALOGUJ PRZEZ GOOGLE'),
            onPressed: _handleGoogleSignIn,
          ),
        ],
      ),
    );
  }
}
