<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<!DOCTYPE html>
<html>
<!-- Configuração de camada - Forms --> 
<div>

    <form novalidate name="form"
          default-button="{{ (currentState == INSERT_STATE) && 'buttonInsert' || 'buttonUpdate' }}">

        <div class="content-tab">

            <div class="form-item position-relative" style="width: 350px;">
                <label class="detail-label" required>Fonte Dados</label>
                <div class="input-group position-relative">
                    <input name="fonteDados" type="text" disabled class="form-control"
                           ng-model="currentEntity.fonteDados.nome"
                           placeholder="Informe a fonte de dados" maxlength="144"
                           ng-minlength="1"
                           ng-hover
                           required>
                    <span class="input-group-btn">
                        <button ng-click="selectFonteDados()" class="btn btn-default"
                                type="button" ng-disabled="currentEntity.id != null">
                            <i class="icon-plus-sign icon-large"></i>
                        </button>
                    </span>
                </div>

                <span ng-show="form.fonteDados.$error.required && (form.$submitted || form.fonteDados.$dirty)" class="tooltip-validation">Fonte de dados obrigatório</span>
            </div>

            <br/>

            <div class="form-item position-relative" style="width: 350px;">
                <label class="detail-label" required>Camada</label>
                <div class="input-group">
                    <input name="camada" type="text" disabled class="form-control"
                           ng-model="currentEntity.nome"
                           placeholder="Informe a camada"
                           maxlength="144" ng-minlength="1"
                           ng-hover
                           required>
                <span
                        class="input-group-btn">
                    <button ng-click="selectCamada()"
                            ng-disabled="currentEntity.fonteDados == null || currentEntity.id != null"
                            class="btn btn-default" type="button">
                        <i class="icon-plus-sign icon-large"></i>
                    </button>
                </span>
                </div>

                <span ng-show="form.camada.$error.required && (form.$submitted || form.camada.$dirty)" class="tooltip-validation">Camada obrigatória</span>
            </div>

            <div ng-if="currentEntity.nome">

                <br/>

                <label class="detail-label">Título</label>

                <div class="position-relative input-group" style="width: 350px;">
                    <input name="titulo" type="text" class="form-control"
                           ng-model="currentEntity.titulo"
                           placeholder="Informe o título"
                           maxlength="144" ng-minlength="1"
                           ng-hover
                           required>
                </div>
                <span ng-show="form.titulo.$error.required && (form.$submitted || form.titulo.$dirty)" class="tooltip-validation">Título obrigatório</span>

                <br/>

                <label class="detail-label">Simbologia</label>

                <div class="position-relative input-group" style="width: 350px;">
                    <img style="border: solid 1px #c9c9c9;" ng-src="{{currentEntity.legenda}}"/>
                </div>

            </div>

            <br/>

            <div class="form-item position-relative" style="width: 350px;">
                <label class="detail-label" required>Grupo de camadas</label>
                <div class="input-group">
                    <input name="grupoCamadas" type="text" disabled class="form-control"
                           ng-model="currentEntity.grupoCamadas.nome"
                           placeholder="Informe o grupo de camada"
                           maxlength="144" ng-minlength="1"
                           ng-hover
                           required>
                    <span class="input-group-btn">
                        <button ng-click="selectGrupoCamada()" class="btn btn-default"
                                type="button">
                            <i class="icon-plus-sign icon-large"></i>
                        </button>
                    </span>
                </div>

                <span ng-show="form.grupoCamadas.$error.required && (form.$submitted || form.grupoCamadas.$dirty)" class="tooltip-validation">Grupo de camada obrigatório</span>
            </div>

            <br/>

            <div class="position-relative" scale-slider ng-model="escalas" style="width: 350px;"></div>
            <div style="width: 350px;">
                <label style="float: left">{{escalas.values[0]}}</label>
                <label style="float: right;">{{escalas.values[1]}}</label>
            </div>

            <br/>

            <div class="form-item position-relative" style="width: 300px;"
                 ng-if="currentState">
                <input type="checkbox" id="grupo" style="width: 20px;"
                       ng-model="currentEntity.habilitada"> <label>Inicia habilitada no mapa</label>

            </div>

            <br/>

            <div class="form-item position-relative" style="width: 300px;"
                 ng-if="currentState">
                <input type="checkbox" style="width: 20px;"
                       ng-model="currentEntity.sistema"
                       ng-disabled="currentState == DETAIL_STATE"> <label>Disponível no menu de camadas</label>

            </div>

            <hr style="border-color: #d9d9d9"/>

            <label class="detail-label">Acesso</label>
            <br/>
            <div class="form-item position-relative radio" style="width: 300px; margin-bottom: 25px">
                <br/>
                <input type="radio" id="publico"
                    ng-model="data.tipoAcesso" style="width: 20px;"
                    ng-disabled="currentState == DETAIL_STATE" value="PUBLICO">
                <label class="radio-label" style="position: relative; top: -2px;"
                       for="publico">Publico </label> <br/> <input type="radio"
                                                                   id="grupos" style="width: 20px;"
                                                                   ng-model="data.tipoAcesso"
                                                                   ng-disabled="currentState == DETAIL_STATE"
                                                                   value="GRUPOS"> <label
                    style="position: relative; top: -2px;" for="grupos"
                    class="radio-label"> Grupos </label>
            </div>

            <button ng-if="data.tipoAcesso == 'GRUPOS'" ng-click="selectGrupoAcesso()" type="button"
                    style="float: right; margin-top: 40px;" class="btn btn-primary">Associar grupo
            </button>

            <br/>

            <div class="form-item position-relative"
                 ng-if="data.tipoAcesso == 'GRUPOS'" style="width: 100%;">
                <div ng-grid="gridAcessoOptions"
                     style="height: 250px; border: 1px solid rgb(212, 212, 212);"></div>

            </div>

       </div>
    </form>
</div>
</html>
