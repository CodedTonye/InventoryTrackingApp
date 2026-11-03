-- V1: MVP schema (single location per business).
-- Money: DECIMAL(15,2). Timestamps: DATETIME(6) in UTC. Enums: VARCHAR.

CREATE TABLE business (
                          id                    BIGINT       NOT NULL AUTO_INCREMENT,
                          name                  VARCHAR(255) NOT NULL,
                          currency              CHAR(3)      NOT NULL,
                          timezone              VARCHAR(64)  NOT NULL DEFAULT 'UTC',
                          default_low_stock_pct DECIMAL(5,2) NOT NULL DEFAULT 20.00,
                          created_at            DATETIME(6)  NOT NULL,
                          PRIMARY KEY (id)
) ENGINE = InnoDB;

CREATE TABLE app_user (
                          id            BIGINT       NOT NULL AUTO_INCREMENT,
                          business_id   BIGINT       NOT NULL,
                          name          VARCHAR(255) NOT NULL,
                          email         VARCHAR(255) NOT NULL,
                          password_hash VARCHAR(255) NOT NULL,
                          role          VARCHAR(30)  NOT NULL,
                          active        BOOLEAN      NOT NULL DEFAULT TRUE,
                          created_at    DATETIME(6)  NOT NULL,
                          PRIMARY KEY (id),
                          CONSTRAINT uq_app_user_email UNIQUE (email),
                          CONSTRAINT fk_app_user_business FOREIGN KEY (business_id) REFERENCES business (id)
) ENGINE = InnoDB;

CREATE TABLE dealer (
                        id            BIGINT       NOT NULL AUTO_INCREMENT,
                        business_id   BIGINT       NOT NULL,
                        name          VARCHAR(255) NOT NULL,
                        phone         VARCHAR(50),
                        email         VARCHAR(255),
                        address       VARCHAR(500),
                        payment_terms VARCHAR(255),
                        notes         TEXT,
                        active        BOOLEAN      NOT NULL DEFAULT TRUE,
                        created_at    DATETIME(6)  NOT NULL,
                        PRIMARY KEY (id),
                        CONSTRAINT fk_dealer_business FOREIGN KEY (business_id) REFERENCES business (id)
) ENGINE = InnoDB;

CREATE TABLE product (
                         id                  BIGINT        NOT NULL AUTO_INCREMENT,
                         version             BIGINT        NOT NULL DEFAULT 0,
                         business_id         BIGINT        NOT NULL,
                         sku                 VARCHAR(64)   NOT NULL,
                         name                VARCHAR(255)  NOT NULL,
                         unit                VARCHAR(30)   NOT NULL DEFAULT 'piece',
                         category            VARCHAR(100),
                         cost_price          DECIMAL(15,2) NOT NULL DEFAULT 0,
                         selling_price       DECIMAL(15,2) NOT NULL DEFAULT 0,
                         quantity_on_hand    INT           NOT NULL DEFAULT 0,
                         reference_level     INT           NOT NULL DEFAULT 0,
                         reorder_pct         DECIMAL(5,2),
                         low_stock_alerted   BOOLEAN       NOT NULL DEFAULT FALSE,
                         preferred_dealer_id BIGINT,
                         active              BOOLEAN       NOT NULL DEFAULT TRUE,
                         created_at          DATETIME(6)   NOT NULL,
                         PRIMARY KEY (id),
                         CONSTRAINT uq_product_business_sku UNIQUE (business_id, sku),
                         CONSTRAINT ck_product_quantity CHECK (quantity_on_hand >= 0),
                         CONSTRAINT fk_product_business FOREIGN KEY (business_id) REFERENCES business (id),
                         CONSTRAINT fk_product_dealer FOREIGN KEY (preferred_dealer_id) REFERENCES dealer (id)
) ENGINE = InnoDB;
CREATE INDEX ix_product_business_active ON product (business_id, active);

CREATE TABLE purchase (
                          id            BIGINT        NOT NULL AUTO_INCREMENT,
                          business_id   BIGINT        NOT NULL,
                          dealer_id     BIGINT        NOT NULL,
                          ref_no        VARCHAR(64),
                          status        VARCHAR(30)   NOT NULL,
                          order_date    DATE          NOT NULL,
                          received_date DATE,
                          total         DECIMAL(15,2) NOT NULL DEFAULT 0,
                          amount_paid   DECIMAL(15,2) NOT NULL DEFAULT 0,
                          created_by    BIGINT        NOT NULL,
                          created_at    DATETIME(6)   NOT NULL,
                          PRIMARY KEY (id),
                          CONSTRAINT fk_purchase_business FOREIGN KEY (business_id) REFERENCES business (id),
                          CONSTRAINT fk_purchase_dealer FOREIGN KEY (dealer_id) REFERENCES dealer (id),
                          CONSTRAINT fk_purchase_user FOREIGN KEY (created_by) REFERENCES app_user (id)
) ENGINE = InnoDB;
CREATE INDEX ix_purchase_business_dealer ON purchase (business_id, dealer_id);

CREATE TABLE purchase_item (
                               id           BIGINT        NOT NULL AUTO_INCREMENT,
                               created_at   DATETIME(6)   NOT NULL,
                               purchase_id  BIGINT        NOT NULL,
                               product_id   BIGINT        NOT NULL,
                               qty_ordered  INT           NOT NULL,
                               qty_received INT           NOT NULL DEFAULT 0,
                               unit_cost    DECIMAL(15,2) NOT NULL,
                               PRIMARY KEY (id),
                               CONSTRAINT fk_purchase_item_purchase FOREIGN KEY (purchase_id) REFERENCES purchase (id),
                               CONSTRAINT fk_purchase_item_product FOREIGN KEY (product_id) REFERENCES product (id)
) ENGINE = InnoDB;

CREATE TABLE purchase_payment (
                                  id          BIGINT        NOT NULL AUTO_INCREMENT,
                                  created_at  DATETIME(6)   NOT NULL,
                                  purchase_id BIGINT        NOT NULL,
                                  amount      DECIMAL(15,2) NOT NULL,
                                  method      VARCHAR(30)   NOT NULL,
                                  paid_at     DATETIME(6)   NOT NULL,
                                  PRIMARY KEY (id),
                                  CONSTRAINT fk_purchase_payment_purchase FOREIGN KEY (purchase_id) REFERENCES purchase (id)
) ENGINE = InnoDB;

CREATE TABLE sale (
                      id            BIGINT        NOT NULL AUTO_INCREMENT,
                      business_id   BIGINT        NOT NULL,
                      receipt_no    VARCHAR(30),
                      customer_name VARCHAR(255),
                      status        VARCHAR(30)   NOT NULL,
                      discount      DECIMAL(15,2) NOT NULL DEFAULT 0,
                      total         DECIMAL(15,2) NOT NULL,
                      amount_paid   DECIMAL(15,2) NOT NULL DEFAULT 0,
                      void_reason   VARCHAR(500),
                      sold_at       DATETIME(6)   NOT NULL,
                      created_by    BIGINT        NOT NULL,
                      created_at    DATETIME(6)   NOT NULL,
                      PRIMARY KEY (id),
                      CONSTRAINT fk_sale_business FOREIGN KEY (business_id) REFERENCES business (id),
                      CONSTRAINT fk_sale_user FOREIGN KEY (created_by) REFERENCES app_user (id)
) ENGINE = InnoDB;
CREATE INDEX ix_sale_business_sold_at ON sale (business_id, sold_at);

CREATE TABLE sale_item (
                           id           BIGINT        NOT NULL AUTO_INCREMENT,
                           created_at   DATETIME(6)   NOT NULL,
                           sale_id      BIGINT        NOT NULL,
                           product_id   BIGINT        NOT NULL,
                           product_name VARCHAR(255)  NOT NULL,
                           quantity     INT           NOT NULL,
                           unit_price   DECIMAL(15,2) NOT NULL,
                           unit_cost    DECIMAL(15,2) NOT NULL,
                           PRIMARY KEY (id),
                           CONSTRAINT fk_sale_item_sale FOREIGN KEY (sale_id) REFERENCES sale (id),
                           CONSTRAINT fk_sale_item_product FOREIGN KEY (product_id) REFERENCES product (id)
) ENGINE = InnoDB;

CREATE TABLE sale_payment (
                              id         BIGINT        NOT NULL AUTO_INCREMENT,
                              created_at DATETIME(6)   NOT NULL,
                              sale_id    BIGINT        NOT NULL,
                              amount     DECIMAL(15,2) NOT NULL,
                              method     VARCHAR(30)   NOT NULL,
                              paid_at    DATETIME(6)   NOT NULL,
                              PRIMARY KEY (id),
                              CONSTRAINT fk_sale_payment_sale FOREIGN KEY (sale_id) REFERENCES sale (id)
) ENGINE = InnoDB;

-- The stock ledger: every change to quantity_on_hand has exactly one row here.
CREATE TABLE stock_movement (
                                id              BIGINT       NOT NULL AUTO_INCREMENT,
                                business_id     BIGINT       NOT NULL,
                                product_id      BIGINT       NOT NULL,
                                type            VARCHAR(30)  NOT NULL,
                                quantity_change INT          NOT NULL,
                                quantity_after  INT          NOT NULL,
                                reference_type  VARCHAR(30),
                                reference_id    BIGINT,
                                reason          VARCHAR(500),
                                created_by      BIGINT,
                                created_at      DATETIME(6)  NOT NULL,
                                PRIMARY KEY (id),
                                CONSTRAINT fk_stock_movement_business FOREIGN KEY (business_id) REFERENCES business (id),
                                CONSTRAINT fk_stock_movement_product FOREIGN KEY (product_id) REFERENCES product (id)
) ENGINE = InnoDB;
CREATE INDEX ix_stock_movement_product ON stock_movement (business_id, product_id, id);

CREATE TABLE task (
                      id          BIGINT       NOT NULL AUTO_INCREMENT,
                      business_id BIGINT       NOT NULL,
                      type        VARCHAR(30)  NOT NULL,
                      title       VARCHAR(255) NOT NULL,
                      description TEXT,
                      status      VARCHAR(30)  NOT NULL,
                      priority    VARCHAR(30)  NOT NULL,
                      due_date    DATE,
                      dealer_id   BIGINT,
                      product_id  BIGINT,
                      quantity    INT,
                      assignee_id BIGINT,
                      created_at  DATETIME(6)  NOT NULL,
                      PRIMARY KEY (id),
                      CONSTRAINT fk_task_business FOREIGN KEY (business_id) REFERENCES business (id),
                      CONSTRAINT fk_task_dealer FOREIGN KEY (dealer_id) REFERENCES dealer (id),
                      CONSTRAINT fk_task_product FOREIGN KEY (product_id) REFERENCES product (id),
                      CONSTRAINT fk_task_assignee FOREIGN KEY (assignee_id) REFERENCES app_user (id)
) ENGINE = InnoDB;
CREATE INDEX ix_task_business_status ON task (business_id, status, due_date);

CREATE TABLE notification (
                              id          BIGINT       NOT NULL AUTO_INCREMENT,
                              business_id BIGINT       NOT NULL,
                              product_id  BIGINT,
                              type        VARCHAR(30)  NOT NULL,
                              message     VARCHAR(500) NOT NULL,
                              seen        BOOLEAN      NOT NULL DEFAULT FALSE,
                              created_at  DATETIME(6)  NOT NULL,
                              PRIMARY KEY (id),
                              CONSTRAINT fk_notification_business FOREIGN KEY (business_id) REFERENCES business (id),
                              CONSTRAINT fk_notification_product FOREIGN KEY (product_id) REFERENCES product (id)
) ENGINE = InnoDB;
CREATE INDEX ix_notification_business_seen ON notification (business_id, seen, created_at);
