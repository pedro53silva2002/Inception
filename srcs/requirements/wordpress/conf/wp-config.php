<?php
#define( 'DB_NAME', getenv('thedatabase') );
#define( 'DB_USER', getenv('theuser') );
#define( 'DB_PASSWORD', getenv('abc') );
#define( 'DB_HOST', getenv('mariadb') );
#define( 'WP_HOME', getenv('https://login.42.fr') );
#define( 'DB_SITEURL', getenv('https://login.42.fr') );

define( 'WP_DEBUG', true );

define( 'DB_NAME', getenv('DB_NAME') );
define( 'DB_USER', getenv('DB_USER') );
define( 'DB_PASSWORD', getenv('DB_PASSWORD') );
define( 'DB_HOST', getenv('DB_HOST') );
define( 'WP_HOME', getenv('WP_FULL_URL') );
define( 'WP_SITEURL', getenv('WP_FULL_URL') );
define( 'DB_CHARSET', 'utf8');
define( 'DB_COLLATE', '');
/* Add any custom values between this line and the "stop editing" line. */

$table_prefix = 'wp_';
/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';