import { ensureLoggedIn, withLoggedIn } from "handlers/auth";
import express, { Express, Router } from "express";

import { ITask } from "pg-promise";
import { Server } from "http";
import bodyParser from "body-parser";
import debug from "debug";
import { mocked } from "ts-jest/utils";
import pool from "server/db-pool";

const log = debug("bobaserver:tests:test-utils");

export const runWithinTransaction = async (
  test: (transaction: ITask<any>) => void
) => {
  await pool.tx("test-transaction", async (t) => {
    await test(t);
    await t.none("ROLLBACK;");
  });
};

export const wrapWithTransaction = async (test: () => void) => {
  jest.mock("server/db-pool", () => ({
    ...jest.requireActual("server/db-pool").default,
    tx: (name: string, transaction: any) =>
      // Because nested transactions are committed the moment they're done, even
      // when a parent transaction exists, we need to make sure that transactions
      // are not actually executed as such during tests. We then turn them into
      // conditional transactions where the condition is always false. This
      // is functionally equivalent (aside from the transaction part).
      jest.requireActual("server/db-pool").default.txIf(
        {
          tag: name,
          cnd: false,
        },
        transaction
      ),
  }));
  try {
    log("starting transaction");
    await pool.none("BEGIN TRANSACTION;");
    await test();
  } finally {
    log("running cleanup");
    await pool.none("ROLLBACK;");
    jest.mock("server/db-pool", () => ({
      ...jest.requireActual("server/db-pool").default,
    }));
  }
};

export const setLoggedInUser = (firebaseId: string) => {
  if (
    !jest.isMockFunction(withLoggedIn) ||
    !jest.isMockFunction(ensureLoggedIn)
  ) {
    throw Error(
      "setLoggedInUser requires 'handlers/auth' to be explicitly mocked."
    );
  }
  mocked(withLoggedIn).mockImplementation((req, res, next) => {
    // @ts-ignore
    req.currentUser = { uid: firebaseId };
    next();
  });
  mocked(ensureLoggedIn).mockImplementation((req, res, next) => {
    // @ts-ignore
    req.currentUser = { uid: firebaseId };
    next();
  });
};

export const startTestServer = (router: Router) => {
  const server: { app: Express | null } = { app: null };
  let listener: Server;
  beforeEach((done) => {
    server.app = express();
    server.app.use(bodyParser.json());
    // We add this middleware cause the server uses it in every request to check
    // logged in status.
    // TODO: extract middleware initialization in its own method and use it here
    // to keep these prerequisite in sync.
    server.app.use(withLoggedIn);
    server.app.use(router);
    listener = server.app.listen(4000, () => {
      done();
    });
  });
  afterEach((done) => {
    listener.close(done);
  });

  return server;
};
