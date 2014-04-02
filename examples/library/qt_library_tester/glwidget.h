#ifndef GLWIDGET_H
#define GLWIDGET_H

#include <QGLWidget>

class GLWidget : public QGLWidget
{
    Q_OBJECT
public:
    explicit GLWidget(const QGLFormat &format, QWidget *parent = 0);
    ~GLWidget();

    QString m_sSceneToOpen;
    void OpenScene(QString const &sFilename);

    // helpers
public:
    static int QKeyToCgeKey(int qKey);

protected:
    static int __cdecl OpenGlLibraryCallback(int eCode, int iParam1, int iParam2, const char *szParam);

private:
    bool m_bAfterInit;

public:
    virtual QSize minimumSizeHint() const;
    virtual QSize sizeHint() const;

protected:
    virtual void initializeGL();
    virtual void paintGL();
    virtual void resizeGL(int width, int height);
    virtual void mousePressEvent(QMouseEvent *event);
    virtual void mouseMoveEvent(QMouseEvent *event);
    virtual void mouseReleaseEvent(QMouseEvent *event);
#ifndef QT_NO_WHEELEVENT
    virtual void wheelEvent(QWheelEvent *event);
#endif
    virtual void keyPressEvent(QKeyEvent *event);
    virtual void keyReleaseEvent(QKeyEvent *event);

private slots:
    void OnUpdateTimer();
};

#endif // GLWIDGET_H
