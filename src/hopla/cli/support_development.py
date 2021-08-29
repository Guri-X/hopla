import logging

import click
import requests

from hopla.hoplalib.common import GlobalConstants
from hopla.hoplalib.http import UrlBuilder, RequestHeaders
from hopla.hoplalib.clickutils import data_on_success_else_exit

log = logging.getLogger()


@click.command()
@click.option("--gems", "-g", type=int, default=4,
              metavar="NUMBER_OF_GEMS", help="The number of gems you wish to contribute")
def support_development(gems: int):
    """Support the development of hopla

    Without options, hopla support-development sends 4 gems to the
    development to be used for testing new features. Use the --gems option
    to change the number of gems send.

    Thanks for supporting Hopla! Your donation is thoroughly appreciated =D.


    \b
    Examples
    -----
    # support development by donating 4 gems
    hopla support-development

    # support development by donating 20 gems
    hopla support-development -g 20


    [APIdocs](https://habitica.com/apidoc/#api-Member-TransferGems)

    \f
    :param gems:
    :return:
    """
    log.debug(f"hopla support-development gems={gems}")
    url = UrlBuilder(path_extension="/members/transfer-gems").url
    headers = RequestHeaders().get_default_request_headers()

    params = {
        "message": "Thanks!",
        "toUserId": GlobalConstants.DEVELOPMENT_UUID,
        "gemAmount": gems
    }

    support_development_request = requests.Request(
        method="POST", url=url, headers=headers, json=params
    )
    response = requests.session().send(support_development_request.prepare())
    response_data = data_on_success_else_exit(response)

    click.echo(response_data)
    click.echo()
    click.echo("Thanks for supporting Hopla! Your donation is thoroughly appreciated =D.")
