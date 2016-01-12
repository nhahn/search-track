module.exports = function (grunt) {
	grunt.registerTask('syncAssets', [
		'jst:dev',
    'concat:coffee',
		'sass:dev',
    'jade:dev',
		'sync:dev',
		'coffee:dev'
	]);
};
