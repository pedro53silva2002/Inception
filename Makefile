# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: peferrei <peferrei@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/01/14 15:47:26 by peferrei          #+#    #+#              #
#    Updated: 2026/01/14 15:47:31 by peferrei         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #


DOCKER_COMPOSE=docker compose

DOCKER_COMPOSE_FILE = ./srcs/docker-compose.yml

all : build

build:
	@$(DOCKER_COMPOSE)  -f $(DOCKER_COMPOSE_FILE) up --build -d
kill:
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) kill
down:
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) down -t 2
clean:
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) down -v -t 2

status : 
	@docker ps

fclean: clean
	docker system prune -a -f

restart: clean build

.PHONY: kill build down clean restart
