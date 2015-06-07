#! /bin/sh
set -e

REV="`dpkg-parsechangelog|grep '^Version: '|sed 's/^Version:\s*\([0-9]*:\)\?\(.*\)-[0-9]*/\2/'`"
SVNREV="`echo ${REV}|grep svn|sed 's/.*svn\([0-9][0-9]*\)$/\1/'`"
DIR="`dpkg-parsechangelog|grep '^Source: '|sed 's/^Source:\s*//'`"
PKGNAME="${DIR}-${REV}"
TARNAME="${DIR}_${REV}"
TRUNK="http://downloads.open-mesh.net/svn/batman/trunk"

# try to download source package
if [ ! -s "${TARNAME}.orig.tar.gz" ]; then
	if [ -z "$SVNREV" ]; then
		uscan --verbose --force-download --download-version "${REV}" --destdir ..
	else
		echo " *** get package from svn"
		rm -rf "$PKGNAME"
		svn -r $SVNREV export "${TRUNK}/${DIR}"@$SVNREV "${PKGNAME}"

		cur_path=`readlink -n -m .`
		for file in `find $PKGNAME -type l`; do
			link=`readlink -n -m "${file}"`
			trunk_file=`echo ${link}|awk '{ print substr($_, '${#cur_path}'+1) }'`
			rm -f "${file}"
			svn -r $SVNREV export "${TRUNK}/${trunk_file}"@$SVNREV "${file}"
		done

		echo " *** build orig.tar.gz"
		MANIFEST="`mktemp -t`"
		find "$PKGNAME" -type f |sed 's/^\.*\/*//'|sort > "$MANIFEST"
		tar cf "../${TARNAME}.orig.tar" --owner 0 --group 0 --numeric-owner --mode 0644 --files-from "$MANIFEST" --no-recursion
		gzip -n -m -f "../${TARNAME}.orig.tar"
		rm -rf "$MANIFEST" "$PKGNAME"
	fi
fi
