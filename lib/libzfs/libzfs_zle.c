/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").
 * You may not use this file except in compliance with the License.
 *
 * You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
 * or http://www.opensolaris.org/os/licensing.
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at usr/src/OPENSOLARIS.LICENSE.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */

/*
 * Copyright 2018 FutureQuest, Inc.
 */

#include <string.h>

#include <libzfs.h>

static char *
safe_strdup(char *str)
{
	char *dupstr = strdup(str);

	if (dupstr == NULL) {
		(void) fprintf(stderr, "internal error: out of memory\n");
		exit(1);
	}

	return (dupstr);
}

static char *
zle_get_env(void) {
	char *_env_zle;
	static char *env_zle = NULL;

	if (env_zle != NULL)
		goto out;

	if ((_env_zle = getenv("ZFS_LIST_EXCLUDE")) == NULL)
		return NULL;

	env_zle = safe_strdup(_env_zle);
out:
	// return a dup as strsep() will be using it
	return safe_strdup(env_zle);
}

boolean_t
has_zle(void) {
	return (zle_get_env()) ? B_TRUE : B_FALSE;
}

boolean_t
is_zle_parent(char *zname)
{
	char *zle_path;
	char *env_zle = zle_get_env();

	while ((zle_path = strsep(&env_zle, ":"))) {
		if (strcmp(zname, zle_path) == 0)
			return B_TRUE;
	}

	return B_FALSE;
}

boolean_t
is_zle_child(char *zname)
{
	char *zle_path;
	char *env_zle = zle_get_env();

	while ((zle_path = strsep(&env_zle, ":"))) {
		if (strncmp(zname, zle_path, strlen(zle_path)) == 0) {
			size_t zle_path_len = strlen(zle_path);
			// check to make sure that zname is a proper exclusion path
			// BAD:  zpool/dockertest
			// GOOD: zpool/docker/test
			if (strlen(zname) > zle_path_len + 1)
				if (zname[zle_path_len] == '/')
					return B_TRUE;
		}
	}

	return B_FALSE;
}
