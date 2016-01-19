var gulp       = require('gulp'),
    gutil      = require('gulp-util'),
    gulpif     = require('gulp-if'),
    streamify  = require('gulp-streamify'),
    autoprefixer = require('gulp-autoprefixer'),
    cssmin     = require('gulp-cssmin'),
    sass       = require('gulp-sass'),
    concat     = require('gulp-concat'),
    plumber    = require('gulp-plumber'),
    source     = require('vinyl-source-stream'),
    babelify   = require('babelify'),
    browserify = require('browserify'),
    watchify   = require('watchify'),
    uglify     = require('gulp-uglify'),
    aliasify   = require('aliasify').configure
    coffee     = require('gulp-coffee'),
    sourcemaps = require('gulp-sourcemaps');
    rename     = require('gulp-rename'),
    glob       = require('glob'),
    jade       = require('gulp-jade'),
    es         = require('event-stream');
    del        = require('del');

var production = process.env.NODE_ENV === 'production';

var dependencies = [
  'alt',
  'react',
  'react-dom',
  'react-router',
  'underscore',
  'react-select',
  'react-router-active-component',
];
/*
 |--------------------------------------------------------------------------
 | Combine the database API files into one API reference 
 |--------------------------------------------------------------------------
 */

gulp.task('clean', function() {
  return del([
    'dist/**/*'
  ]);
});

gulp.task('img', function() {
  return gulp.src(['assets/img/**/*'], {base: 'assets'}).pipe(gulp.dest('dist'));
});

gulp.task('manifest', function() {
  return gulp.src(['assets/manifest.json']).pipe(gulp.dest('dist'));
});

gulp.task('api', function() {
  return gulp.src([
    'assets/api/*.coffee', 
    '!assets/api/dbAPI.coffee', 
    '!assets/api/dexieScopes.coffee', 
    'assets/api/dexieScopes.coffee' ,
    'assets/api/dbAPI.coffee'
  ]).pipe(sourcemaps.init())
  .pipe(concat('trackAPI.coffee'))
  .pipe(coffee({bare: true}))
  .pipe(gulpif(production, uglify({ mangle: false })))
  .pipe(sourcemaps.write())
  .pipe(gulp.dest('dist'));
});

/*
 |--------------------------------------------------------------------------
 | Compile all of our background files 
 |--------------------------------------------------------------------------
 */

gulp.task('background', function() {
  return gulp.src([
    'assets/background/*.coffee',
  ]).pipe(sourcemaps.init())
  .pipe(coffee({bare: true}))
  .pipe(gulpif(production, uglify({ mangle: false })))
  .pipe(sourcemaps.write())
  .pipe(gulp.dest('dist/background'));
});

gulp.task('background-html', function() {
  return gulp.src('assets/background/background.jade')
    .pipe(jade())
    .pipe(gulp.dest('dist/background'));
});

/*
 |--------------------------------------------------------------------------
 | Combine all JS libraries into a single file for ease of use 
 |--------------------------------------------------------------------------
 */
gulp.task('vendor', function() {
  return gulp.src([
    'vendor/jquery/dist/jquery.js',
    '/vendor/uri.js/src/URI.min.js',
    '/vendor/bluebird/js/browser/bluebird.min.js',
    'vendor/dexie/dist/latest/Dexie.js',
    'vendor/dexie/addons/Dexie.Observable/Dexie.Observable.js',
    'vendor/js-logger/src/logger.min.js',
    'vendor/bootstrap/dist/js/bootstrap.js',
    'vendor/magnific-popup/dist/jquery.magnific-popup.js',
    'vendor/toastr/toastr.js',
  ]).pipe(sourcemaps.init())
    .pipe(concat('vendor.js'))
    .pipe(gulpif(production, uglify({ mangle: false })))
    .pipe(sourcemaps.write())
    .pipe(gulp.dest('dist'));
});

/*
 |--------------------------------------------------------------------------
 | Compile third-party dependencies separately for faster performance.
 |--------------------------------------------------------------------------
 */
gulp.task('browserify-vendor', function() {
  return browserify()
    .require(dependencies)
    .transform(aliasify, {aliases: { "react": "./node_modules/react/react.js"}})
    .bundle()
    .pipe(source('vendor.bundle.js'))
    .pipe(gulpif(production, streamify(uglify({ mangle: false }))))
    .pipe(gulp.dest('dist'));
});

/*
 |--------------------------------------------------------------------------
 | Compile only project files, excluding all third-party dependencies.
 |--------------------------------------------------------------------------
 */
gulp.task('browserify', function(done) {
  glob('./assets/*-app/main.js', function(err, files) {
    if(err) done(err);
    var tasks = files.map(function(entry) {
      return browserify(entry)
        .external(dependencies)
        .transform(babelify, {presets: ['es2015', 'react']})
        .bundle()
        .pipe(source(entry))
        .pipe(rename(function(path) {
          path.dirname = path.dirname.substring(7);
          return path;
        }))
        .pipe(gulpif(production, streamify(uglify({ mangle: false }))))
        .pipe(gulp.dest('./dist'));
      });
    es.merge(tasks).on('end', done);
  })
});


/*
 |--------------------------------------------------------------------------
 | Same as browserify task, but will also watch for changes and re-compile.
 |--------------------------------------------------------------------------
 */
gulp.task('browserify-watch', ['browserify-vendor'], function(done) {
  glob('./assets/*-app/main.js', function(err, files) {
    if(err) done(err);
    var tasks = files.map(function(entry) {
      var bundler = watchify(browserify(entry, watchify.args));
      bundler.external(dependencies);
      bundler.transform(babelify, {presets: ['es2015', 'react']});
      bundler.on('update', rebundle);
      return rebundle();

      function rebundle() {
        var start = Date.now();
        return bundler.bundle()
          .on('error', function(err) {
            gutil.log(gutil.colors.red(err.toString()));
          })
          .on('end', function() {
            gutil.log(gutil.colors.green('Finished rebundling ' + entry + ' in', (Date.now() - start) + 'ms.'));
          })
          .pipe(source(entry))
          .pipe(rename(function(path) {
            path.dirname = path.dirname.substring(7);
            return path;
          }))
          .pipe(gulp.dest('./dist'));
      }
    
      es.merge(tasks).on('end', done);
    });
  });
  
});

/*
 |--------------------------------------------------------------------------
 | Compile the react applications' main HTML pages 
 |--------------------------------------------------------------------------
 */

gulp.task('react-html', function() {
  return gulp.src('assets/*-app/main.jade', {base: 'assets'})
    .pipe(jade())
    .pipe(gulp.dest('./dist'));
});

/*
 |--------------------------------------------------------------------------
 | Compile LESS stylesheets.
 |--------------------------------------------------------------------------
 */
gulp.task('styles', function() {
    return gulp.src([
      'assets/*-app/stylesheets/*.scss'], {base: 'assets'})
    .pipe(plumber())
    .pipe(sass({includePaths: ['node_modules', 'vendor']}))
    .pipe(autoprefixer())
    .pipe(gulpif(production, cssmin()))
    .pipe(gulp.dest('dist'));
});

gulp.task('watch', function() {
  var change = function(event) { gutil.log(gutil.colors.green('Detected change in ' + event.path)) };
  gulp.watch('assets/*-app/main.jade', ['react-html']).on('change', change);
  gulp.watch('assets/*-app/stylesheets/*.scss', ['styles']).on('change', change);
  gulp.watch('assets/api/*.coffee', ['api']).on('change', change); 
  gulp.watch('assets/background/*.coffee', ['background']).on('change', change);
  gulp.watch('assets/background/background.jade', ['background-html']).on('change', change);
  gulp.watch('assets/img/**/*', ['img']).on('change', change);
  gulp.watch('assets/manifest.json', ['manifest']).on('change', change);
});

gulp.task('default', ['api', 'img', 'manifest', 'styles', 'vendor', 'background', 'background-html', 'react-html', 'browserify-watch', 'watch']);
gulp.task('build', ['api', 'img', 'manifest', 'styles', 'background', 'background-html', 'vendor', 'browserify', 'react-html']);
