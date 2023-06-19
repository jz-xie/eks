import os
from datetime import timedelta

# Eliminate flask_wtf.csrf.CSRFError: 400 Bad Request: The CSRF token is missing.
WTF_CSRF_ENABLED = False


PUBLIC_ROLE_LIKE = "Gamma"

APP_NAME = "Data Visualization - Superset"
APP_ICON = "/static/assets/images/logo.png"
FAVICONS = [{"href": "/static/assets/images/logo_favicon.png"}]

SECRET_KEY = os.getenv("SUPERSET_APP_SECRET_KEY", "")
REDIST_HOST = os.getenv("REDIS_HOST")


DATA_CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": int(timedelta(days=1).total_seconds()),
    "CACHE_KEY_PREFIX": "superset_data_",
    "CACHE_REDIS_URL": f"redis://{REDIST_HOST}:6379",
}

FILTER_STATE_CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": int(timedelta(days=1).total_seconds()),
    "CACHE_KEY_PREFIX": "superset_filter_",
    "CACHE_REDIS_URL": f"redis://{REDIST_HOST}:6379",
}

EXPLORE_FORM_DATA_CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": int(timedelta(days=1).total_seconds()),
    "CACHE_KEY_PREFIX": "superset_explore_",
    "CACHE_REDIS_URL": f"redis://{REDIST_HOST}:6379",
}

from flask_appbuilder.security.manager import AUTH_OAUTH

AUTH_TYPE = AUTH_OAUTH
ENABLE_PROXY_FIX = True
OAUTH_PROVIDERS = [
    {
        "name": "oidc",
        "token_key": "access_token",  # Name of the token in the response of access_token_url
        "icon": "fa-address-card",  # Icon for the provider
        "remote_app": {
            "client_id": "3gbe826leph9abn66oih86dkq",  # Client Id (Identify Superset application)
            "client_secret": os.getenv(
                "SUPERSET_AWS_COGNITO_CLIENT_SECRET", ""
            ),  # Secret for this Client Id (Identify Superset application)
            "server_metadata_url": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_K0ExlDFez/.well-known/openid-configuration",
        },
    }
]
# Map Authlib roles to superset roles
AUTH_ROLE_ADMIN = "Admin"
AUTH_ROLE_PUBLIC = "Public"
# Will allow user self registration, allowing to create Flask users from Authorized User
AUTH_USER_REGISTRATION = True
# The default user self registration role
AUTH_USER_REGISTRATION_ROLE = "Public"
# if we should replace ALL the user's roles each login, or only on registration
# AUTH_ROLES_SYNC_AT_LOGIN = True

# Timeout duration for SQL Lab synchronous queries
SQLLAB_TIMEOUT = int(timedelta(minutes=5).total_seconds())
GUNICORN_TIMEOUT = int(timedelta(minutes=5).total_seconds())
# This is an important setting, and should be lower than your
# [load balancer / proxy / envoy / kong / ...] timeout settings.
# You should also make sure to configure your WSGI server
# (gunicorn, nginx, apache, ...) timeout setting to be <= to this setting
SUPERSET_WEBSERVER_TIMEOUT = int(timedelta(minutes=5).total_seconds())


FEATURE_FLAGS = {"DASHBOARD_RBAC": True}

# Do you want Talisman enabled?
TALISMAN_ENABLED = True
# If you want Talisman, how do you want it configured??
TALISMAN_CONFIG = {
    "content_security_policy": None,
    "force_https": True,
    "force_https_permanent": False,
}

import json
import logging
from base64 import b64decode

from superset.security import SupersetSecurityManager


def get_user_group(jwt_token) -> list:
    import jwt

    id_token = jwt_token["id_token"]
    info = jwt.decode(id_token, options={"verify_signature": False})
    user_groups = info["cognito:groups"]
    return user_groups


class CustomSsoSecurityManager(SupersetSecurityManager):
    def oauth_user_info(self, provider, response=None):
        # logging.debug("Oauth2 provider: {0}.".format(provider))
        if provider == "oidc":
            id_token = self.appbuilder.sm.oauth_remotes[provider].token
            user_groups = get_user_group(id_token)
            me = self.appbuilder.sm.oauth_remotes[provider].userinfo()
            # logging.debug("user_data: {0}".format(me))
            role_map = {
                # 'datascience': 'Gamma',
                #   'data-engineering': 'Alpha',
                "admin": "Admin"
            }
            roles = [role_map[key] for key in user_groups if key in role_map]
            # user_role = ['admin' for i in user_groups if ]
            user_payload = {
                "name": me["preferred_username"],
                "email": me["email"],
                "id": me["email"],
                "username": me["email"].split("@")[0],
                "first_name": me["given_name"],
                "last_name": me["family_name"],
            }
            if len(roles) > 0:
                user_payload["role"] = roles[0]

            return user_payload

    def auth_user_oauth(self, userinfo):
        """
        OAuth user Authentication

        :userinfo: dict with user information the keys have the same name
        as User model columns.
        """
        if "username" in userinfo:
            user = self.find_user(username=userinfo["username"])
        elif "email" in userinfo:
            user = self.find_user(email=userinfo["email"])
        else:
            user = False
            logging.error(
                "User info does not have username or email {0}".format(
                    userinfo
                )
            )
            # logging.debug(
            #     "user after find_user={}. type={}".format(user, type(user))
            # )

        # return None
        # User is disabled
        # if user and not user.is_active:
        #     logger.info(LOGMSG_WAR_SEC_LOGIN_FAILED.format(userinfo))
        #     return None
        # If user does not exist on the DB and not self user registration, go away
        if not user and not self.auth_user_registration:
            logging.debug(
                "user does not exist on the DB and not self user registration, go away"
            )
            return None
        # User does not exist, create one if self registration.
        if not user:
            if userinfo.get("role"):
                default_role = self.find_role(userinfo["role"])
            else:
                aur = self.auth_user_registration_role
                default_role = self.find_role(aur)

            user = self.add_user(
                username=userinfo["username"],
                first_name=userinfo.get("first_name", ""),
                last_name=userinfo.get("last_name", ""),
                email=userinfo.get("email", ""),
                role=default_role,
            )
            logging.debug("Adding user with role={} ".format(default_role))
            if not user:
                logging.error(
                    "Error creating a new OAuth user %s" % userinfo["username"]
                )
                return None
            else:
                logging.debug("Success!")
        logging.debug("final user before update ={}".format(user))
        self.update_user_auth_stat(user)
        return user


CUSTOM_SECURITY_MANAGER = CustomSsoSecurityManager
