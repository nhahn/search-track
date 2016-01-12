module.exports = function (grunt) {
	grunt.registerTask('compileAssets', [
		'clean:dev',
    'concat:coffee',
		'jst:dev',
    'jade:dev',
		'sass:dev',
		'copy:dev',
		'coffee:dev',
    'update_json:bower',
    'update_json:manifest'
	]);
};
