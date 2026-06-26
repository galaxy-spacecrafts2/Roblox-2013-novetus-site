import {
    Cookies,
    CurrentUser,
    Dialog,
    Endpoints,
    EnvironmentUrls,
    Lang,
    PlaceLauncher
} from 'Roblox';
import $ from 'jquery';
import GameLauncher from './gameLauncher';

const NOVETUS_CLIENT_NAME = '2013L';
const NOVETUS_PROTOCOL = 'novetus';
const NOVETUS_DOWNLOAD_URL = 'https://github.com/nicemre/Novetus/releases/latest';

const NovetusClientInterface = {};

function getPlaceLauncherUrl(requestType, otherParams) {
    let absoluteUrl = ' ';
    if (Endpoints && Endpoints.Urls) {
        absoluteUrl = `${Endpoints.getAbsoluteUrl('/Game/PlaceLauncher.ashx')}?`;
    }

    if (absoluteUrl[0] !== 'h') {
        const domainUrl = `http://${window.location.host}`;
        absoluteUrl = domainUrl + '/Game/PlaceLauncher.ashx?';
    }
    absoluteUrl = absoluteUrl.replace('placelauncher', 'PlaceLauncher');

    const args = {
        request: requestType,
        browserTrackerId: Cookies.getBrowserTrackerId()
    };
    $.extend(args, otherParams);
    return absoluteUrl + $.param(args);
}

function doAuthTicketRequest() {
    const authUrl = `${EnvironmentUrls.authApi}/v1/authentication-ticket/`;
    return $.ajax({
        method: 'POST',
        url: authUrl,
        contentType: 'application/json'
    });
}

function getAuthTicket(params) {
    const deferred = new $.Deferred();
    const result = Object.assign({}, params);

    if (!CurrentUser.isAuthenticated) {
        deferred.resolve(result);
        return deferred;
    }

    return doAuthTicketRequest().then(function (data, textStatus, xhr) {
        const authTicket = xhr.getResponseHeader('RBX-Authentication-Ticket');
        if (authTicket && authTicket.length > 0) {
            result.authTicket = authTicket;
            deferred.resolve(result);
        } else {
            deferred.reject();
        }
        return deferred;
    });
}

function launchNovetusUri(params) {
    const deferred = new $.Deferred();

    let uri = `${NOVETUS_PROTOCOL}://launch?client=${encodeURIComponent(NOVETUS_CLIENT_NAME)}`;

    if (params.placeLauncherUrl) {
        uri += `&script=${encodeURIComponent(params.placeLauncherUrl)}`;
    }

    if (params.authTicket) {
        uri += `&ticket=${encodeURIComponent(params.authTicket)}`;
    }

    if (CurrentUser && CurrentUser.userId) {
        uri += `&userid=${encodeURIComponent(CurrentUser.userId)}`;
    }

    if (CurrentUser && CurrentUser.name) {
        uri += `&username=${encodeURIComponent(CurrentUser.name)}`;
    }

    if (GameLauncher.gameLaunchLogger) {
        GameLauncher.gameLaunchLogger.logToConsole(`NovetusClientInterface launchUri: ${uri}`);
    }

    let iframe = $('iframe#gamelaunch');
    if (iframe.length > 0) {
        iframe.remove();
    }
    iframe = $("<iframe id='gamelaunch' class='hidden'></iframe>").attr('src', uri);
    $('body').append(iframe);

    deferred.resolve(params);
    return deferred;
}

function showLaunchDialog(onClose) {
    const refactorEnabled = PlaceLauncher &&
        PlaceLauncher.Resources &&
        PlaceLauncher.Resources.RefactorEnabled === 'True';

    if (refactorEnabled) {
        const bodyContent = (PlaceLauncher.Resources.ProtocolHandlerStartingDialog &&
            PlaceLauncher.Resources.ProtocolHandlerStartingDialog.play &&
            PlaceLauncher.Resources.ProtocolHandlerStartingDialog.play.content) || '';
        const loader = (PlaceLauncher.Resources.ProtocolHandlerStartingDialog &&
            PlaceLauncher.Resources.ProtocolHandlerStartingDialog.loader) || '';
        Dialog.open({
            bodyContent: bodyContent + loader,
            allowHtmlContentInBody: true,
            showAccept: false,
            showDecline: false,
            dismissable: false,
            cssClass: 'protocolhandler-starting-modal',
            onCloseCallback: onClose,
            onCancel() {
                onClose();
                $.modal.close();
            }
        });
        return;
    }

    $('#ProtocolHandlerStartingDialog').modal({
        escClose: true,
        opacity: 80,
        overlayCss: { backgroundColor: '#000' },
        onClose() {
            onClose();
            $.modal.close();
        },
        zIndex: 1031
    });
}

function showInstallDialog(params) {
    $.modal.close();

    const titleText = Lang && Lang.VisitGameResources &&
        Lang.VisitGameResources['Heading.NeedToInstall'] ||
        'Novetus não instalado';

    Dialog.open({
        titleText: titleText,
        bodyContent:
            '<p>Para jogar, você precisa instalar o <strong>Novetus</strong> (cliente 2013L).</p>' +
            '<p><a href="' + NOVETUS_DOWNLOAD_URL + '" target="_blank" rel="noopener noreferrer">' +
            'Clique aqui para baixar o Novetus</a></p>',
        allowHtmlContentInBody: true,
        acceptText: 'Baixar Novetus',
        showDecline: true,
        declineText: (Lang && Lang.ControlsResources && Lang.ControlsResources['Action.Cancel']) || 'Cancelar',
        onAccept: function () {
            window.open(NOVETUS_DOWNLOAD_URL, '_blank', 'noopener,noreferrer');
        }
    });
}

function startGameFlow(params) {
    $(GameLauncher).trigger(GameLauncher.startClientAttemptedEvent, {
        launchMethod: 'Novetus',
        params: params
    });

    showLaunchDialog(function () {});

    return getAuthTicket(params)
        .then(launchNovetusUri)
        .then(function (resolvedParams) {
            setTimeout(function () {
                $.modal.close();
                $(GameLauncher).trigger(GameLauncher.startClientSucceededEvent, {
                    launchMethod: 'Novetus',
                    params: resolvedParams
                });
            }, 4000);
            return resolvedParams;
        }, function () {
            $.modal.close();
            Dialog.open({
                titleText: (Lang && Lang.VisitGameResources && Lang.VisitGameResources['Heading.ErrorStartingGame']) || 'Erro ao iniciar',
                bodyContent: (Lang && Lang.VisitGameResources && Lang.VisitGameResources['Response.Dialog.ErrorLaunching']) || 'Não foi possível iniciar o jogo.',
                acceptText: (Lang && Lang.ControlsResources && Lang.ControlsResources['Action.OK']) || 'OK',
                showDecline: false
            });
        });
}

function joinMultiplayerGame(placeLauncherParams) {
    const placeLauncherUrl = getPlaceLauncherUrl('RequestGame', placeLauncherParams);
    return startGameFlow({
        placeLauncherUrl: placeLauncherUrl,
        placeId: placeLauncherParams.placeId,
        launchMode: 'play'
    });
}

function followPlayerIntoGame(placeLauncherParams) {
    const placeLauncherUrl = getPlaceLauncherUrl('RequestFollowUser', placeLauncherParams);
    return startGameFlow({
        placeLauncherUrl: placeLauncherUrl,
        launchMode: 'play'
    });
}

function joinGameInstance(placeLauncherParams) {
    const placeLauncherUrl = getPlaceLauncherUrl('RequestGameJob', placeLauncherParams);
    return startGameFlow({
        placeLauncherUrl: placeLauncherUrl,
        placeId: placeLauncherParams.placeId,
        launchMode: 'play'
    });
}

function joinPrivateGame(placeLauncherParams) {
    const placeLauncherUrl = getPlaceLauncherUrl('RequestPrivateGame', placeLauncherParams);
    return startGameFlow({
        placeLauncherUrl: placeLauncherUrl,
        placeId: placeLauncherParams.placeId,
        launchMode: 'play'
    });
}

function playTogetherGame(placeLauncherParams) {
    const placeLauncherUrl = getPlaceLauncherUrl('RequestPlayTogetherGame', placeLauncherParams);
    return startGameFlow({
        placeLauncherUrl: placeLauncherUrl,
        placeId: placeLauncherParams.placeId,
        launchMode: 'play'
    });
}

function openStudio() {
    return startGameFlow({ launchMode: 'edit' });
}

function returnToStudio() {
    return startGameFlow({ launchMode: 'edit', task: 'ReturnFromLogin' });
}

function editGameInStudio(placeId, universeId, allowUpload) {
    return startGameFlow({ launchMode: 'edit', placeId, universeId });
}

function openPluginInStudio(pluginId) {
    return startGameFlow({ launchMode: 'plugin', pluginId });
}

function tryAssetInStudio(assetId) {
    return startGameFlow({ launchMode: 'asset', assetId });
}

function startDownload() {
    window.open(NOVETUS_DOWNLOAD_URL, '_blank', 'noopener,noreferrer');
}

Object.assign(NovetusClientInterface, {
    joinMultiplayerGame,
    followPlayerIntoGame,
    joinGameInstance,
    joinPrivateGame,
    playTogetherGame,
    openStudio,
    returnToStudio,
    editGameInStudio,
    openPluginInStudio,
    tryAssetInStudio,
    startDownload,
    showInstallDialog,
    doAuthTicketRequest
});

$(document).ready(function () {
    GameLauncher.setGameLaunchInterface(NovetusClientInterface);
});

export default NovetusClientInterface;
