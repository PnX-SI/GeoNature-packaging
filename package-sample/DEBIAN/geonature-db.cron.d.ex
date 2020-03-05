#
# Regular cron jobs for the geonature-db package
#
0 4	* * *	root	[ -x /usr/bin/geonature-db_maintenance ] && /usr/bin/geonature-db_maintenance
