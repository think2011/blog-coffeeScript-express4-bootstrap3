// Generated by CoffeeScript 1.7.1
(function() {
  var User, mongodb;

  mongodb = require('./db');

  User = (function() {
    function User(user) {
      this.name = user.name, this.password = user.password, this.email = user.email, this.avatar = user.avatar;
    }


    /* 读取 */

    User.get = function(name, callback) {
      return mongodb.open(function(err, db) {
        if (err) {
          callback(err);
        }
        return db.collection('users', function(err, collection) {
          if (err) {
            mongodb.close();
            return callback(err);
          }
          return collection.findOne({
            name: name
          }, function(err, user) {
            mongodb.close();
            if (err) {
              return callback(err);
            }
            return callback(null, user);
          });
        });
      });
    };


    /* 保存 */

    User.prototype.save = function(callback) {
      var user;
      user = {
        name: this.name,
        email: this.email,
        avatar: this.avatar,
        password: this.password
      };
      return mongodb.open(function(err, db) {
        if (err) {
          return callback(err);
        }
        return db.collection('users', function(err, collection) {
          if (err) {
            mongodb.close();
            return callback(err);
          }
          return collection.insert(user, {
            safe: true
          }, function(err, user) {
            mongodb.close();
            if (err) {
              return callback(err);
            }
            return callback(null, user[0]);
          });
        });
      });
    };

    return User;

  })();

  module.exports = User;

}).call(this);

//# sourceMappingURL=user.map