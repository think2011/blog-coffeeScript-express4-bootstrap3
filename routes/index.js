// Generated by CoffeeScript 1.7.1
(function() {
  var Comment, Post, User, checkLogin, checkNotLogin, crypto, formidable, fs, moment, mongodb, settings;

  fs = require('fs');

  crypto = require('crypto');

  moment = require('moment');

  User = require('../models/user');

  Post = require('../models/post');

  Comment = require('../models/comment');

  formidable = require('formidable');

  moment.lang('zh-cn');

  checkNotLogin = function(req, res, next) {
    if (!req.session.user) {
      req.flash('error', '请登录');
      return res.redirect('/login');
    }
    return next();
  };

  checkLogin = function(req, res, next) {
    if (req.session.user) {
      req.flash('error', '您已登录');
      return res.redirect('back');
    }
    return next();
  };

  settings = require('../settings');

  mongodb = require('mongodb').Db;

  module.exports = function(app) {
    app.get('/a', function(req, res) {
      mongodb.connect(settings.url, function(err, db) {
        console.log(err);
        return console.log(db);
      });
      return res.send('123123');
    });
    app.get('/', function(req, res) {
      var page;
      page = req.query.p ? +req.query.p : 1;
      return Post.getPage(null, page, function(err, posts, total) {
        var v, _fn, _i, _len;
        if (err) {
          posts = [];
        }
        _fn = function(v) {
          return v.date = moment(v.time).startOf().fromNow();
        };
        for (_i = 0, _len = posts.length; _i < _len; _i++) {
          v = posts[_i];
          _fn(v);
        }
        return res.render('index', {
          title: '首页',
          posts: posts,
          page: page,
          total: total,
          totalPage: Math.ceil(total / 6),
          isFirst: (page - 1) === 0,
          isLast: ((page - 1) * 6 + posts.length) === total,
          user: req.session.user,
          success: req.flash('success').toString(),
          error: req.flash('error').toString()
        });
      });
    });
    app.get('/search', function(req, res) {
      return Post.search(req.query.keyword, function(err, posts) {
        var k, refactor, v, _fn, _i, _len;
        if (err) {
          req.flash('error', err);
          return res.redirect('/');
        }
        refactor = [];
        _fn = function(v) {
          var temp, _ref;
          v.smallDate = moment(v.time).format('YYYY MMMM');
          v.date = moment(v.time).format('Do dddd hh:mm:ss');
          temp = (_ref = refactor[v.smallDate]) != null ? _ref : refactor[v.smallDate] = [];
          return temp.push(v);
        };
        for (_i = 0, _len = posts.length; _i < _len; _i++) {
          v = posts[_i];
          _fn(v);
        }
        posts = [];
        for (k in refactor) {
          v = refactor[k];
          posts.push({
            date: k,
            list: v
          });
        }
        return res.render('archive', {
          title: "" + req.query.keyword + " 的搜索结果",
          posts: posts,
          user: req.session.user,
          success: req.flash('success').toString(),
          error: req.flash('error').toString()
        });
      });
    });
    app.get('/archive', function(req, res) {
      return Post.getArchive(function(err, posts) {
        var k, refactor, v, _fn, _i, _len;
        if (err) {
          req.flash('error', err);
          return res.redirect('/');
        }
        refactor = [];
        _fn = function(v) {
          var temp, _ref;
          v.smallDate = moment(v.time).format('YYYY MMMM');
          v.date = moment(v.time).format('Do dddd hh:mm:ss');
          temp = (_ref = refactor[v.smallDate]) != null ? _ref : refactor[v.smallDate] = [];
          return temp.push(v);
        };
        for (_i = 0, _len = posts.length; _i < _len; _i++) {
          v = posts[_i];
          _fn(v);
        }
        posts = [];
        for (k in refactor) {
          v = refactor[k];
          posts.push({
            date: k,
            list: v
          });
        }
        return res.render('archive', {
          title: '存档',
          posts: posts,
          user: req.session.user,
          success: req.flash('success').toString(),
          error: req.flash('error').toString()
        });
      });
    });
    app.get('/tags', function(req, res) {
      return Post.getTags(function(err, posts) {
        if (err) {
          req.flash('error', err);
          return res.redirect('/');
        }
        return res.render('tags', {
          title: '标签',
          posts: posts,
          user: req.session.user,
          success: req.flash('success').toString(),
          error: req.flash('error').toString()
        });
      });
    });
    app.get('/tags/:tag', function(req, res) {
      return Post.getTag(req.params.tag, function(err, posts) {
        var k, refactor, v, _fn, _i, _len;
        if (err) {
          req.flash('error', err);
          return res.redirect('/');
        }
        refactor = [];
        _fn = function(v) {
          var temp, _ref;
          v.smallDate = moment(v.time).format('YYYY MMMM');
          v.date = moment(v.time).format('Do dddd hh:mm:ss');
          temp = (_ref = refactor[v.smallDate]) != null ? _ref : refactor[v.smallDate] = [];
          return temp.push(v);
        };
        for (_i = 0, _len = posts.length; _i < _len; _i++) {
          v = posts[_i];
          _fn(v);
        }
        posts = [];
        for (k in refactor) {
          v = refactor[k];
          posts.push({
            date: k,
            list: v
          });
        }
        return res.render('archive', {
          title: "标记为 " + req.params.tag + " 的文章",
          posts: posts,
          user: req.session.user,
          success: req.flash('success').toString(),
          error: req.flash('error').toString()
        });
      });
    });
    app.get('/reg', checkLogin);
    app.get('/reg', function(req, res) {
      return res.render('reg', {
        title: '注册',
        user: req.session.user,
        success: req.flash('success').toString(),
        error: req.flash('error').toString()
      });
    });
    app.get('/reg', checkLogin);
    app.post('/reg', function(req, res) {
      var avatar, email, md5, name, newUser, password, password_re;
      name = req.body.name;
      email = req.body.email;
      password = req.body.password;
      password_re = req.body.password_re;
      if (password !== password_re) {
        req.flash('error', '两次输入的密码不一致');
        return res.redirect('/reg');
      }
      md5 = crypto.createHash('md5');
      avatar = md5.update(email.toLowerCase()).digest('hex');
      md5 = crypto.createHash('md5');
      password = md5.update(password).digest('hex');
      newUser = new User({
        name: name,
        email: email,
        avatar: avatar,
        password: password
      });
      return User.get(name, function(err, user) {
        if (user) {
          req.flash('error', '用户已存在');
          return res.redirect('/reg');
        }
        return newUser.save(function(err, user) {
          if (err) {
            req.flash('error', err);
            return res.redirect('/reg');
          }
          req.session.user = user;
          req.flash('success', '注册成功');
          return res.redirect('/');
        });
      });
    });
    app.get('/login', checkLogin);
    app.get('/login', function(req, res) {
      return res.render('login', {
        title: '登录',
        user: req.session.user,
        success: req.flash('success').toString(),
        error: req.flash('error').toString()
      });
    });
    app.get('/login', checkLogin);
    app.post('/login', function(req, res) {
      var md5, password;
      md5 = crypto.createHash('md5');
      password = md5.update(req.body.password).digest('hex');
      return User.get(req.body.name, function(err, user) {
        if (!user) {
          req.flash('error', '用户名不存在');
          return res.redirect('/login');
        }
        if (user.password !== password) {
          req.flash('error', '密码错误');
          return res.redirect('/login');
        }
        req.session.user = user;
        req.flash('success', '登录成功');
        return res.redirect('/');
      });
    });
    app.get('/upload', checkNotLogin);
    app.get('/upload', function(req, res) {
      return res.render('upload', {
        title: '上传',
        user: req.session.user,
        success: req.flash('success').toString(),
        error: req.flash('error').toString()
      });
    });
    app.post('/upload', checkNotLogin);
    app.post('/upload', function(req, res) {
      var filesBox, form, uploadDir;
      uploadDir = './public/upload/';
      filesBox = [];
      form = new formidable.IncomingForm();
      form.uploadDir = './temp';
      return form.parse(req, function(err, fields, files) {
        var k, v;
        for (k in files) {
          v = files[k];
          if (v.size > 0) {
            fs.renameSync(v.path, uploadDir + v.name);
            filesBox.push("<p>![](" + ('/upload/' + v.name) + ")</p>");
          }
        }
        req.flash('success', "上传成功 " + (filesBox.join('')));
        return res.redirect('/upload');
      });
    });
    app.get('/post', checkNotLogin);
    app.get('/post', function(req, res) {
      return res.render('post', {
        title: '发表',
        user: req.session.user,
        success: req.flash('success').toString(),
        error: req.flash('error').toString()
      });
    });
    app.get('/post', checkNotLogin);
    app.post('/post', function(req, res) {
      var avatar, currentUser, md5, post;
      currentUser = req.session.user;
      md5 = crypto.createHash('md5');
      avatar = md5.update(currentUser.email.toLowerCase()).digest('hex');
      post = new Post({
        name: currentUser.name,
        avatar: avatar,
        title: req.body.title,
        post: req.body.post,
        tags: req.body.tags
      });
      return post.save(function(err) {
        if (err) {
          req.flash('error', err);
          return res.redirect('/post');
        }
        req.flash('success', '发布成功');
        return res.redirect('/');
      });
    });
    app.get('/u/:name', function(req, res) {
      return User.get(req.params.name, function(err, user) {
        var page;
        if (!user) {
          req.flash('error', '用户不存在');
          return res.redirect('/');
        }
        page = req.query.p ? +req.query.p : 1;
        return Post.getPage(user.name, page, function(err, posts, total) {
          var v, _fn, _i, _len;
          if (err) {
            req.flash('error', err);
            return res.redirect('/');
          }
          _fn = function(v) {
            return v.date = moment(v.time).startOf().fromNow();
          };
          for (_i = 0, _len = posts.length; _i < _len; _i++) {
            v = posts[_i];
            _fn(v);
          }
          return res.render('user', {
            title: "" + user.name + "的文章",
            posts: posts,
            page: page,
            totalPage: Math.ceil(total / 10),
            isFirst: (page - 1) === 0,
            isLast: ((page - 1) * 10 + posts.length) === total,
            user: req.session.user,
            success: req.flash('success').toString(),
            error: req.flash('error').toString()
          });
        });
      });
    });
    app.get('/u/:name/:day/:title', function(req, res) {
      var params;
      params = req.params;
      return Post.getOne(params.name, params.day, params.title, function(err, post) {
        var i, _fn, _i, _len, _ref;
        if (err) {
          req.flash('error', err);
          return res.redirect('/');
        }
        post.date = moment(post.time).startOf().fromNow();
        _ref = post.comments;
        _fn = function() {
          return i.date = moment(i.time).startOf().fromNow();
        };
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          i = _ref[_i];
          _fn();
        }
        return res.render('article', {
          title: params.title,
          user: req.session.user,
          post: post,
          success: req.flash('success').toString(),
          error: req.flash('error').toString()
        });
      });
    });
    app.post('/u/:name/:day/:title', function(req, res) {
      var comment, newComment, params;
      params = req.params;
      comment = {
        name: req.body.name || '陌生人',
        content: req.body.content,
        time: Date.now()
      };
      newComment = new Comment({
        name: params.name,
        title: params.title,
        time: params.day,
        comment: comment
      });
      return newComment.save(function(err) {
        if (err) {
          req.flash('error', err);
          return res.redirect('back');
        }
        req.flash('success', '评论成功');
        return res.redirect('back');
      });
    });
    app.get('/edit/:name/:day/:title', checkNotLogin);
    app.get('/edit/:name/:day/:title', function(req, res) {
      var params;
      params = req.params;
      return Post.edit(params.name, params.day, params.title, function(err, post) {
        if (err) {
          req.flash('error', err);
          return res.redirect('back');
        }
        return res.render('edit', {
          title: "编辑 " + params.title,
          user: req.session.user,
          post: post,
          success: req.flash('success').toString(),
          error: req.flash('error').toString()
        });
      });
    });
    app.post('/edit/:name/:day/:title', checkNotLogin);
    app.post('/edit/:name/:day/:title', function(req, res) {
      var currentUser, params;
      params = req.params;
      currentUser = req.session.user;
      return Post.update(currentUser.name, params.day, params.title, req.body.post, req.body.tags, function(err, post) {
        var url;
        url = "/u/" + currentUser.name + "/" + params.day + "/" + params.title;
        if (err) {
          req.flash('error', err);
          return res.redirect(url);
        }
        req.flash('success', '编辑成功');
        return res.redirect(url);
      });
    });
    app.get('/remove/:name/:day/:title', checkNotLogin);
    app.get('/remove/:name/:day/:title', function(req, res) {
      var currentUser, params;
      params = req.params;
      currentUser = req.session.user;
      return Post.remove(currentUser.name, params.day, params.title, function(err, post) {
        if (err) {
          req.flash('error', err);
          return res.redirect('back');
        }
        req.flash('success', '删除成功');
        return res.redirect('/');
      });
    });
    app.get('/logout', checkNotLogin);
    return app.get('/logout', function(req, res) {
      req.session.user = null;
      req.flash('success', '注销成功');
      return res.redirect('/');
    });
  };

}).call(this);

//# sourceMappingURL=index.map
